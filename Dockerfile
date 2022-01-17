FROM quay.io/eduk8s/base-environment:master

# Allow install as non-root user
USER root
RUN chmod g+w /usr/local/bin

USER 1001

COPY --chown=1001:0 . /home/eduk8s/

RUN mv /home/eduk8s/workshop /opt/workshop

RUN fix-permissions /home/eduk8s

