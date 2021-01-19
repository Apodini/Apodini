FROM swift:5.3-amazonlinux2

#COPY . /src/
#WORKDIR /src/

RUN yum -y install zip sqlite-devel

# RUN ls

# RUN yum -y install \
#     libuuid-devel \
#     libicu-devel \
#     libedit-devel \
#     libxml2-devel \
#     sqlite-devel \
#     python-devel \
#     ncurses-devel \
#     curl-devel \
#     openssl-devel \
#     libtool \
#     jq \
#     tar \
#     zip


# CMD swift build --product TestWebServiceAWS -c debug

# CMD python /app/app.py