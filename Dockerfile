# FROM kallikrein/cordova

# MAINTAINER Revanth Reddy Malé <malerevanthreddy3099@gmail.com>

# RUN \
# apt-get update && \
# apt-get install -y lib32stdc++6 lib32z1

# # download and extract android sdk
# RUN curl http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz | tar xz -C /usr/local/
# ENV ANDROID_HOME /usr/local/android-sdk-linux
# ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# # update and accept licences
# RUN ( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) | /usr/local/android-sdk-linux/tools/android update sdk --no-ui -a --filter platform-tool,build-tools-24.4.1,android-24; \
#     find /usr/local/android-sdk-linux -perm 0744 | xargs chmod 755

# ENV GRADLE_USER_HOME /src/gradle
# VOLUME /src
# WORKDIR /src


# ------------------------------------------

# FROM beevelop/cordova:latest
# MAINTAINER Revanth Reddy Malé <malerevanthreddy3099@gmail.com>
# WORKDIR /opt
# RUN \
# apt-get update && \
# apt-get install -y wget unzip
# RUN wget -q https://services.gradle.org/distributions/gradle-4.1-all.zip
# RUN chmod 775 /opt/gradle-4.1-all.zip
# RUN mkdir -p /opt/gradle-4.1/wrapper/dists/
# RUN unzip gradle-4.1-all.zip -d /opt/gradle-4.1/wrapper/dists/
# RUN mv /opt/gradle-4.1/wrapper/dists/gradle-4.1/bin/gradle /opt/gradle-4.1/wrapper/dists/gradle-4.1/bin/gradle4
# RUN chmod 775 /opt/gradle-4.1/wrapper/dists/gradle-4.1/bin/gradle4
# RUN wget -q https://repo1.maven.org/maven2/com/google/j2objc/j2objc-annotations/1.1/j2objc-annotations-1.1.jar \
#     && unzip j2objc-annotations-1.1.jar -d /opt
# ENV GRADLE_HOME /opt/gradle-4.1
# ENV GRADLE_USER_HOME /opt/gradle-4.1
# ENV PATH $PATH:/usr/bin
# ENV ANDROID_HOME=/opt/android
# ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle
# WORKDIR /opt/android/tools/bin
# RUN ./sdkmanager --update
# RUN mkdir "$ANDROID_HOME/licenses"
# RUN echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > "$ANDROID_HOME/licenses/android-sdk-license"
# RUN echo "8933bad161af4178b1185d1a37fbf41ea5269c55" >> "$ANDROID_HOME/licenses/android-sdk-license"
# RUN echo "84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"
# RUN npm install -g @angular/cli
# WORKDIR /workspace
# ENV PATH $PATH:/opt/android/tools/bin
# ENV PATH $PATH:/opt/gradle-4.1/wrapper/dists/gradle-4.1/bin/


# ------------------------------------------------------

FROM oddlid/arch-cli-minimal:latest

# Temporarily uninstall ca-certificates-utils to get rid of the 
# ca-certificates-utils: /etc/ssl/certs/ca-certificates.crt exists in filesystem error
# See: https://bbs.archlinux.org/viewtopic.php?id=223895
# It will be reinstalled later on
RUN  pacman -Rdd --noconfirm ca-certificates-utils

# Install packages for both ease of use and 
# structurally needed for PhantomJS (fontconfig) and Node
RUN pacman -Syy
RUN pacman -S --noconfirm --needed ca-certificates-utils harfbuzz fontconfig nodejs npm
RUN pacman -S --noconfirm --needed nano htop wget

# Archlinux CN repo (has yaourt and sometimes other interesting tools)
RUN echo "[archlinuxcn]" >> /etc/pacman.conf && \
echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf && \
echo "Server = http://repo.archlinuxcn.org/\$arch" >> /etc/pacman.conf

# Add BBQLinux repo for Android development: http://bbqlinux.org/
RUN echo "[bbqlinux]" >> /etc/pacman.conf && \
echo "Server = http://packages.bbqlinux.org/\$repo/os/\$arch" >> /etc/pacman.conf && \
pacman-key -r 04C0A941 && \
pacman-key --lsign-key 04C0A941

# Add multilib repo for the Android SDK (it requires 32bit libs)
RUN sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /etc/pacman.conf && \
sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /etc/pacman.conf && \
sed -i 's/#\[multilib\]/\[multilib\]/g' /etc/pacman.conf

# Update and force a refresh of all package lists even if they appear up to date.
RUN pacman -Syyu --noconfirm

# Install all the repo keyrings and mirrorlists
RUN pacman --noconfirm -S archlinuxcn-keyring bbqlinux-keyring

# Install yaourt, package-query and cower for easy AUR usage.
# TODO make sure package query still exists later after yaourt uninstall
RUN pacman -S --noconfirm yaourt package-query cower

# Ensure the system locale is English
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Set up basic aliases for convenience
RUN echo "alias ll='ls -alF'" >> ~/.bashrc
RUN echo "alias la='ls -A'" >> ~/.bashrc
RUN echo "alias l='ls -CF'" >> ~/.bashrc

# Install pacman base devel to allow building packages from AUR
# RUN pacman -S --noconfirm --needed base-devel git

# Install Oracle Java
RUN yaourt -S --noconfirm --needed jdk

# Install Android SDK
RUN pacman -S --noconfirm android-sdk

# Install Android build tools
RUN yes | /opt/android-sdk/tools/bin/sdkmanager "platforms;android-25" "build-tools;25.0.2" "extras;google;m2repository" "extras;android;m2repository"

# Set up Cordova
RUN npm install -g cordova