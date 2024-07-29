#!/bin/bash

# running common-script all functions
checkEnv
JDK_VERSION="17"



# Install JDK
debian_install() {
  echo "sudo password required"
  sudo -v
  echo "Installing JDK ${JDK_VERSION}"
  sudo apt-get install -y wget apt-transport-https gnupg
  sudo wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
  sudo echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
  sudo apt-get update
  sudo apt-get install temurin-"${JDK_VERSION}"-jdk
}

rhel_install () {
  sudo -v
  sudo cat << EOF | sudo tee /etc/yum.repos.d/adoptium.repo
  [Adoptium]
  name=Adoptium
  baseurl=https://packages.adoptium.net/artifactory/rpm/centos/8/$(uname -m)
  enabled=1
  gpgcheck=1
  gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

  sudo yum clean all
  sudo yum update
  sudo yum install temurin-"${JDK_VERSION}"-jdk
}

suse_install () {
  sudo zypper ar -f "https://packages.adoptium.net/artifactory/rpm/opensuse/$(. /etc/os-release; echo "$VERSION_ID")/$(uname -m)" adoptium
  sudo zypper install temurin-"${JDK_VERSION}"-jdk
}




echo "Distro : ${DTYPE}"
echo "Packager: ${PACKAGER}"

# ask user to select jdk version
PS3="Please select JDK version: "
options=("JDK8" "JDK11" "JDK17" "JDK21" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "JDK8")
            JDK_VERSION="8"; break ;;
        "JDK11")
            JDK_VERSION="11"; break ;;
        "JDK17")
            JDK_VERSION="17"; break ;;
        "JDK21")
            JDK_VERSION="21"; break ;;
        "Quit")
            exit 1;;
        *) echo "invalid option $REPLY";;
    esac
done


echo -e "${YELLOW} JDK Version: ${JDK_VERSION}"
echo -e "${RC}"

if [ "$PACKAGER" = "apt-get" ]; then
    debian_install
elif [ "$PACKAGER" = "yum" ] || [ "$PACKAGER" = "dnf" ]; then
    rhel_install
elif [ "$PACKAGER" = "zypper" ]; then
    suse_install
else
    echo "Unsupported packager."
    exit 1
fi


sudo rm -f wget-log
