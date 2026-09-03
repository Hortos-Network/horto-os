#!/usr/bin/env python3
"""Wyoming TTS wrapper for rkvoice-stream backend."""

from __future__ import annotations

import argparse
import asyncio
import io
import logging
import math
import time
import wave
from functools import partial
from pathlib import Path
import httpx

from wyoming.audio import AudioChunk, AudioStart, AudioStop
from wyoming.error import Error
from wyoming.event import Event
from wyoming.info import Attribution, Describe, Info, TtsProgram, TtsVoice
from wyoming.server import AsyncEventHandler, AsyncServer
from wyoming.tts import (
    Synthesize,
    SynthesizeChunk,
    SynthesizeStart,
    SynthesizeStop,
    SynthesizeStopped,
)

logging.basicConfig(level=logging.INFO)
_LOGGER = logging.getLogger("rkvoice-stream-wyoming")

DEFAULT_URI = "tcp://0.0.0.0:10200"
DEFAULT_BACKEND_URL = "http://rkvoice-stream:8621"
DEFAULT_SAMPLES_PER_CHUNK = 1024


class RkvoiceStreamClient:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")

    async def synthesize(self, text: str) -> bytes:
        url = f"{self.base_url}/tts"
        payload = {"text": text}

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            return response.content


class RkvoiceEventHandler(AsyncEventHandler):
    def __init__(
        self,
        reader,
        writer,
        client: RkvoiceStreamClient,
        info: Info,
        samples_per_chunk: int,
        auto_punctuation: str,
        no_streaming: bool,
    ) -> None:
        super().__init__(reader, writer)
        self.client = client
        self.info_event = info.event()
        self.samples_per_chunk = samples_per_chunk
        self.auto_punctuation = auto_punctuation
        self.no_streaming = no_streaming
        self.is_streaming = False
        self.stream_text = ""

    async def handle_event(self, event: Event) -> bool:
        _LOGGER.debug("Received Wyoming event: %s", event.type)

        if Describe.is_type(event.type):
            await self.write_event(self.info_event)
            return True

        try:
            if Synthesize.is_type(event.type):
                if self.is_streaming:
                    return True

                synthesize = Synthesize.from_event(event)
                await self._handle_synthesize(synthesize)
                return True

            if self.no_streaming:
                return True

            if SynthesizeStart.is_type(event.type):
                self.is_streaming = True
                self.stream_text = ""
                return True

            if SynthesizeChunk.is_type(event.type):
                chunk = SynthesizeChunk.from_event(event)
                self.stream_text += chunk.text
                return True

            if SynthesizeStop.is_type(event.type):
                synthesize = Synthesize(text=self.stream_text)
                await self._handle_synthesize(synthesize)
                await self.write_event(SynthesizeStopped().event())
                self.is_streaming = False
                self.stream_text = ""
                return True
        except Exception as err:
            _LOGGER.exception("Synthesis failed")
            await self.write_event(Error(text=str(err), code=err.__class__.__name__).event())
            return True

        return True

    async def _handle_synthesize(self, synthesize: Synthesize) -> None:
        text = self._normalize_text(synthesize.text, self.auto_punctuation)
        if not text:
            await self.write_event(AudioStart(rate=22050, width=2, channels=1).event())
            await self.write_event(AudioStop().event())
            return

        _LOGGER.info("Synthesizing text via rkvoice-stream: %s", text)
        synth_start_time = time.perf_counter()

        try:
            wav_bytes = await self.client.synthesize(text)
        except Exception as err:
            _LOGGER.error("Failed to connect to rkvoice-stream backend: %s", err)
            raise

        synth_elapsed_ms = (time.perf_counter() - synth_start_time) * 1000

        with wave.open(io.BytesIO(wav_bytes), "rb") as wav_file:
            rate = wav_file.getframerate()
            width = wav_file.getsampwidth()
            channels = wav_file.getnchannels()
            audio_seconds = wav_file.getnframes() / max(1, rate)
            audio_bytes = wav_file.readframes(wav_file.getnframes())

        await self.write_event(AudioStart(rate=rate, width=width, channels=channels).event())

        bytes_per_sample = width * channels
        bytes_per_chunk = bytes_per_sample * self.samples_per_chunk
        num_chunks = int(math.ceil(len(audio_bytes) / bytes_per_chunk))

        for i in range(num_chunks):
            offset = i * bytes_per_chunk
            chunk = audio_bytes[offset : offset + bytes_per_chunk]
            await self.write_event(AudioChunk(audio=chunk, rate=rate, width=width, channels=channels).event())

        await self.write_event(AudioStop().event())

        total_elapsed_ms = (time.perf_counter() - synth_start_time) * 1000
        _LOGGER.info(
            "TTS completed: synth=%.0f ms audio=%.2f sec chunks=%s",
            synth_elapsed_ms,
            audio_seconds,
            num_chunks,
        )

    def _normalize_text(self, text: str, auto_punctuation: str) -> str:
        text = " ".join(text.strip().splitlines())
        if text and auto_punctuation and text[-1] not in auto_punctuation:
            text += auto_punctuation[0]
        return text


def build_info(voice_name: str) -> Info:
    return Info(
        tts=[
            TtsProgram(
                name="rkvoice-stream",
                description="NPU-accelerated TTS engine via rkvoice-stream",
                version="1.0.0",
                attribution=Attribution(name="Horto-OS", url="https://github.com"),
                installed=True,
                voices=[
                    TtsVoice(
                        name=voice_name,
                        description=f"Default NPU Voice ({voice_name})",
                        version="1.0.0",
                        attribution=Attribution(name="Horto-OS", url="https://github.com"),
                        installed=True,
                        languages=["en", "fr", "de"],
                    )
                ],
                supports_synthesize_streaming=True,
            )
        ]
    )


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--uri", default=DEFAULT_URI)
    parser.add_argument("--backend-url", default=DEFAULT_BACKEND_URL)
    parser.add_argument("--voice", default="default")
    parser.add_argument("--samples-per-chunk", type=int, default=DEFAULT_SAMPLES_PER_CHUNK)
    parser.add_argument("--auto-punctuation", default=".?!。？！．؟")
    parser.add_argument("--no-streaming", action="store_true")
    args = parser.parse_args()

    client = RkvoiceStreamClient(args.backend_url)
    info = build_info(args.voice)
    server = AsyncServer.from_uri(args.uri)

    _LOGGER.info("Starting Wyoming rkvoice-stream bridge on %s (backend: %s)", args.uri, args.backend_url)

    await server.run(
        partial(
            RkvoiceEventHandler,
            client=client,
            info=info,
            samples_per_chunk=args.samples_per_chunk,
            auto_punctuation=args.auto_punctuation,
            no_streaming=args.no_streaming,
        )
    )


if __name__ == "__main__":
    asyncio.run(main())
