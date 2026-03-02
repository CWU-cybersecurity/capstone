import pexpect
import sys
import os
import random
import time

# tested setoolkit version 8.0.3

# configurations
TARGET_EMAIL = "partsale26@gmail.com" # target email
SENDER_EMAIL_1 = "didioil256@gmail.com" # sender email
GMAIL_PASSWORD_1 = "cjas mgmv grkc yapg" # Use an App Password, not your real one
SET_PROMPT = r"set.*>" 

SENDER_NAME_1 = "Jamie"
TARGET_SUBJECT_1 = "People & Culture news"
TARGET_BODY_1 = """
<table width="100%" bgcolor="#eeeeee" cellpadding="20">
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
</table>
"""

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

SENDER_NAME_3 = "System Admin"
TARGET_SUBJECT_3 = "Database Maintenance Notification"
TARGET_BODY_3 = """
<div style="border: 1px solid #444; padding: 15px; background-color: #111;">
    <h3 style="margin-top: 0; color: #fff;">[SYSTEM ADVISORY]</h3>
    <p><strong>SERVICE:</strong> Database-Cluster-01<br>
    <strong>EVENT:</strong> Routine Patching & Kernel Update<br>
    <strong>WINDOW:</strong> Saturday 02:00 UTC - 04:00 UTC</p>
    <p>Secondary nodes will handle traffic during the primary reboot. No downtime is anticipated for the production environment.</p>
    <p style="color: #888;">-- Automated Ops-Bot-04</p>
</div>
"""

SENDER_NAME_4 = "Security Team"
TARGET_SUBJECT_4 = "Password Change Confirmation"
TARGET_BODY_4 = """
<div style="max-width: 500px; margin: 20px auto; border: 1px solid #dcdcdc; padding: 20px;">
    <img src="https://via.placeholder.com/150x40?text=Corporate+Logo" alt="Logo" style="margin-bottom: 20px;">
    <h2 style="font-size: 18px;">Security Notification</h2>
    <p>This is a confirmation that the password for your corporate account was successfully changed on <strong>March 1, 2026</strong>.</p>
    <p>If you performed this action, you can safely ignore this email. No further action is required.</p>
    <p style="font-size: 12px; color: #999;">If you did NOT change your password, please contact the Security Operations Center immediately at ext. 5555.</p>
</div>
"""

SENDER_NAME_5 = "Payroll Team"
TARGET_SUBJECT_5 = "Payroll Document Available for Download"
TARGET_BODY_5 = """
<div style="max-width: 600px; border: 1px solid #bdc3c7;">
    <div style="background-color: #2c3e50; color: white; padding: 15px; text-align: center; font-weight: bold;">
        Payroll & Benefits Portal
    </div>
    <div style="padding: 25px;">
        <p>Dear Colleague,</p>
        <p>Your <strong>W-2 Tax Statement</strong> for the previous fiscal year is now available for download in the secure payroll portal.</p>
        <p style="text-align: center; margin: 25px;">
            <a href="https://portal.company-internal.local/payroll" style="background-color: #27ae60; color: white; padding: 10px 20px; text-decoration: none; border-radius: 3px;">Access My Documents</a>
        </p>
        <p>Please note that for security reasons, this link is only accessible while connected to the corporate VPN.</p>
    </div>
</div>
"""

templates = [
        (SENDER_NAME_1, TARGET_SUBJECT_1, TARGET_BODY_1),
        (SENDER_NAME_2, TARGET_SUBJECT_2, TARGET_BODY_2),
        (SENDER_NAME_3, TARGET_SUBJECT_3, TARGET_BODY_3),
        (SENDER_NAME_4, TARGET_SUBJECT_4, TARGET_BODY_4),
        (SENDER_NAME_5, TARGET_SUBJECT_5, TARGET_BODY_5)
]

email_templates = [
    ("test email 1", "test app password"),
    ("test email 2", "test app password")
]

def run_spear_phish(SENDER_NAME, TARGET_SUBJECT, TARGET_BODY, SENDER_EMAIL = SENDER_EMAIL_1, SENDER_PASS = GMAIL_PASSWORD_1):
    print(f"[+] Starting SET...")
    # set timeout for 20 seconds to communicate with setoolkit
    child = pexpect.spawn('sudo setoolkit', encoding='utf-8', timeout=20)
    child.logfile_read = sys.stdout

    # initalize the list of templates so we can randomly select and remove them as we use them


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
    child.sendline(TARGET_SUBJECT)

    # FIX: Match the prompt exactly as it appeared in your logs
    child.expect("Send the message as html or plain")
    child.sendline("h") 

    child.expect("Enter the body of the message")
    child.sendline(TARGET_BODY)
    child.sendline("END") # Sending END immediately after body

    child.expect("Send email to:")
    child.sendline(TARGET_EMAIL)

    # SET asks if you want to use a Gmail account (1) or Custom SMTP (2)
    child.expect(SET_PROMPT)
    child.sendline("1")

    child.expect("Your gmail email address:")
    child.sendline(SENDER_EMAIL_1)

    # Note: SET asks for 'FROM NAME', then 'password', then 'priority'
    child.expect("The FROM NAME the user will see:")
    child.sendline(SENDER_NAME)

    child.expect("Email password:")
    child.sendline(GMAIL_PASSWORD_1)

    child.expect("priority")
    child.sendline("yes")

    child.expect("attach a file")
    child.sendline("n")

    child.expect("inline file")
    child.sendline("n")

    print("\n[+] Sequence complete. Waiting for SET to finish sending...")

    '''
    # Instead of child.interact(), wait for the final output or a timeout
    try:
        # SET usually prints "Email has been sent" or returns to a prompt
        child.expect(["Email has been sent", SET_PROMPT], timeout=30)
        print("\n[SUCCESS] SET finished the mailing process.")
    except pexpect.TIMEOUT:
        print("\n[!] Timeout waiting for confirmation, but commands were sent.")
    '''
    # --- 3. CLEANUP ---
    try:
        child.expect(["Email has been sent", SET_PROMPT], timeout=30)
        print("\n[SUCCESS] Email sent.")
    except:
        print("\n[!] Finished with timeout/unknown state.")
    # Properly shut down the child process
    child.close()

if __name__ == "__main__":
    while(len(templates) > 0):
        # randomly select one of the 5 templates
        selected_template = random.choice(templates)
        templates.remove(selected_template) # remove it so we don't reuse it if we loop again
        SENDER_NAME, TARGET_SUBJECT, TARGET_BODY = selected_template

        '''
        # use this with multiple gmails

        if (len(selected_sender_email) > 0 ): # if email template exists
            selected_sender_email = random.choice(email_templates)
            templates.remove(selected_sender_email)
            SELECTED_EMAIL, SELECTED_PASS = selected_sender_email
            run_spear_phish(SENDER_NAME, TARGET_SUBJECT, TARGET_BODY, SELECTED_EMAIL, SELECTED_PASS)
        else: # otherwise use default email.
            run_spear_phish(SENDER_NAME, TARGET_SUBJECT, TARGET_BODY)
        '''
        
        # for testing
        run_spear_phish(SENDER_NAME, TARGET_SUBJECT, TARGET_BODY)
        
        print("Mail sent successful")
        time.sleep(30)
        