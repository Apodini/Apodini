FROM swift:5.3-amazonlinux2

ARG USER_ID
ARG GROUP_ID
ARG USERNAME

RUN yum -y install zip sqlite-devel

RUN groupadd --gid $GROUP_ID $USERNAME \
    && useradd -s /bin/bash --uid $USER_ID --gid $GROUP_ID -m $USERNAME

USER $USERNAME
