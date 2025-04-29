# Install necessary packages
sudo apt install python3-venv

# Create a virtual environment
python3 -m venv myenv

# Activate the virtual environment
source myenv/bin/activate

# Install bcrypt in the virtual environment
pip install bcrypt

# Create the Python script to generate the bcrypt hash
echo 'import bcrypt

# Ask the user to input a password
new_password = input("Enter the password you want to hash: ")

# Generate the bcrypt hash
hashed_password = bcrypt.hashpw(new_password.encode("utf-8"), bcrypt.gensalt())

# Print the hashed password
print("New hashed password:", hashed_password.decode("utf-8"))' > generate_hash.py

# Run the Python script
python generate_hash.py
