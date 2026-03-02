import pexpect
import sys
import os

# tested setoolkit version 8.0.3

# configurations
TARGET_EMAIL = "" # target email
SENDER_EMAIL = "" # sender email
GMAIL_PASSWORD = "" # Use an App Password, not your real one
SET_PROMPT = r"set.*>" 

SENDER_NAME_1 = "Jamie"
TARGET_SUBJECT_1 = "People & Culture news"
TARGET_BODY_1 = """<table width="100%" bgcolor="#eeeeee" cellpadding="20">
    <tr>
        <td>
            <table width="600" align="center" bgcolor="#ffffff" style="padding: 30px; border-radius: 8px;">
                <tr>
                    <td>
                        <h1 style="color: #e91e63; margin-top: 0;">People & Culture</h1>
                        <p style="font-size: 16px;"><strong>Welcome our New Hires!</strong></p>
                        <p>Please join us in welcoming Sarah Jenkins (Marketing) and David Chen (DevOps) to the team this week.</p>
                        <hr style="border: 0; border-top: 1px solid #eee;">
                        <p><strong>Reminder:</strong> Open enrollment for health benefits closes this Friday at 5:00 PM. Please ensure your selections are updated in the HRIS system.</p>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>"""

SENDER_NAME_2 = "Kally"
TARGET_SUBJECT_2 = "Invoice #INC-88291"
TARGET_BODY_2 = """
<div style="max-width: 600px; margin: auto; background: white; padding: 20px; border: 1px solid #ddd; border-radius: 4px;">
    <div style="border-bottom: 2px solid #0052cc; padding-bottom: 10px; margin-bottom: 20px;">
        <span style="color: #0052cc; font-weight: bold; font-size: 18px;">IT Service Desk</span>
    </div>
    <p><strong>Ticket #INC-88291 has been updated.</strong></p>
    <p>Hello User,</p>
    <p>The status of your request <em>"Printer connectivity issues - Floor 3"</em> has been changed to <strong>Resolved</strong>.</p>
    <p><strong>Comments:</strong><br>Driver cache cleared and spooler service restarted. Please test and let us know if the issue persists.</p>
    <p style="font-size: 13px; color: #666;">View full ticket details in the <a href="#" style="color: #0052cc;">Employee Portal</a>.</p>
</div>
"""

def run_spear_phish():
    print(f"[+] Starting SET...")
    # set timeout for 20 seconds to communicate with setoolkit
    child = pexpect.spawn('sudo setoolkit', encoding='utf-8', timeout=20)
    child.logfile_read = sys.stdout

    # --- HANDLE STARTUP SCREENS ---
    # This loop keeps hitting Enter until we see the main menu prompt
    while True:
        # We look for the menu OR the common "press enter" prompts
        index = child.expect([
            SET_PROMPT, 
            "Press {return} to continue", 
            "press <return> to continue", 
            "Do you agree to the terms",
            pexpect.TIMEOUT
        ], timeout=15)

        if index == 0: # Found the menu!
            break
        elif index == 1 or index == 2: # Press Enter prompt
            child.sendline("")
        elif index == 3: # Agreement prompt
            child.sendline("yes")
        elif index == 4: # Timeout
            print("\n[!] SET took too long to respond. Check if sudo is asking for a password.")
            child.interact() # Let you see what's wrong
            return

 # --- MENU NAVIGATION ---
    print("\n[+] Reached Main Menu. Sending commands...")
    
    child.sendline("1") # social-engineering attacks
    child.expect(SET_PROMPT)
    
    child.sendline("5") # mass mailer attack
    child.expect(SET_PROMPT)
    
    child.sendline("1") # e-mail attack single email address
    child.expect(SET_PROMPT)

    child.sendline("2") # one time use email template

    # FIX: We must EXPECT the subject prompt before sending the subject
    child.expect("Subject of the email:")
    child.sendline(TARGET_SUBJECT_2)

    # FIX: Match the prompt exactly as it appeared in your logs
    child.expect("Send the message as html or plain")
    child.sendline("h") 

    child.expect("Enter the body of the message")
    child.sendline(TARGET_BODY_2)
    child.sendline("END") # Sending END immediately after body

    child.expect("Send email to:")
    child.sendline(TARGET_EMAIL)

    # SET asks if you want to use a Gmail account (1) or Custom SMTP (2)
    child.expect(SET_PROMPT)
    child.sendline("1")

    child.expect("Your gmail email address:")
    child.sendline(SENDER_EMAIL)

    # Note: SET asks for 'FROM NAME', then 'password', then 'priority'
    child.expect("The FROM NAME the user will see:")
    child.sendline(SENDER_NAME_2)

    child.expect("Email password:")
    child.sendline(GMAIL_PASSWORD)

    child.expect("priority")
    child.sendline("yes")

    child.expect("attach a file")
    child.sendline("n")

    child.expect("inline file")
    child.sendline("n")

    print("\n[+] Sequence complete. Waiting for SET to finish sending...")

    # Instead of child.interact(), wait for the final output or a timeout
    try:
        # SET usually prints "Email has been sent" or returns to a prompt
        child.expect(["Email has been sent", SET_PROMPT], timeout=30)
        print("\n[SUCCESS] SET finished the mailing process.")
    except pexpect.TIMEOUT:
        print("\n[!] Timeout waiting for confirmation, but commands were sent.")
    
    # Properly shut down the child process
    child.close()

if __name__ == "__main__":
    run_spear_phish()