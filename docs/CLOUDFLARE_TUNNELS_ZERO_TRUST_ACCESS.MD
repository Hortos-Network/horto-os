# Cloudflare Tunnels Zero Trust Access

**Summary**: Gate your tunnel behind Cloudflare’s Zero Trust Access

---

To gate your tunnel behind Cloudflare’s Zero Trust Access rules (so that anyone trying to hit your SSH tunnel or web apps is forced to authenticate first), you configure an **Access Application**.

Here is the quick step-by-step guide to setting it up in the Cloudflare Zero Trust Dashboard:

### Step 1: Navigate to Access Applications

1. Log in to your [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/).
    
2. On the left sidebar, go to **Access** > **Applications**.
    
3. Click the **Add an application** button.
    

### Step 2: Configure the Application Settings

1. Select **Self-hosted** as the application type.
    
2. Fill out the basic settings:
    
    - **Application name:** Give it a clear label (e.g., `Horto Node SSH` or `Horto Dashboard`).
        
    - **Session Duration:** Choose how long a user stays authenticated before needing to log in again (e.g., `24 hours`).
        
    - **Application Domain:** Enter your exact subdomain route (e.g., `ssl-hos1.hortos.dev` or `homepage.hortos.dev`).
        
3. Click **Next**.
    

### Step 3: Create the Access Policy (The ACL Rules)

This is where you define **who** is allowed to pass through the tunnel.

1. **Policy Name:** Give the rule a name (e.g., `Allow Admin Access`).
    
2. **Action:** Leave it set to **Allow**.
    
3. **Configure Rules (Configure "Include" criteria):**
    
    - Under **Selector**, choose how you want to authenticate. The most common options are:
        
        - **Emails:** (e.g., `your-personal-email@gmail.com`) — Cloudflare will email you a secure One-Time PIN (OTP) when you try to connect.
            
        - **Login Methods:** Restrict it to a specific integrated identity provider if you use one (like GitHub, Google, etc.).
            
        - **IP Ranges:** Restrict access only to your home or trusted static IP blocks.
            
4. Click **Next**, leave the advanced settings on default, and click **Add application**.
    

### How it changes your connection flow:

Once this Access Policy is active, the very next time you try to connect via Remmina (or your terminal), your local `cloudflared` client will automatically intercept the connection, open a browser window requesting your authentication (or prompt for your email OTP), and only pass the traffic through to your NanoPi _after_ Cloudflare verifies your identity.