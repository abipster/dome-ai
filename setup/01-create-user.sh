#!/bin/bash

USERNAME=dome
USERID=1000

# create new user
echo "Creating user: $USERNAME with UID: $USERID"
useradd -u $USERID -m $USERNAME -s /bin/bash

# set user password
echo "Setting password"
#passwd dome
echo "$USERNAME:$(cat dome.passwd)" | chpasswd

# remove password file
rm dome.passwd

# confirm user is created
getent passwd | grep $USERNAME

echo "Adding user to sudo and docker groups"
# add user to sudo group
usermod -aG sudo $USERNAME

# add user to docker group
usermod -aG docker $USERNAME

# create required directories
echo "Creating required directories"
mkdir /opt/dome
chown $USERNAME:$USERNAME /opt/dome

echo "Done"