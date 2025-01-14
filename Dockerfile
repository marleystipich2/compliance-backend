FROM registry.access.redhat.com/ubi8/ruby-27


USER 0

# Install dependencies and clean cache to make the image cleaner
# also remove unused packages added by ubi8/s2i-base.
RUN yum install -y hostname shared-mime-info jq && \
    yum remove -y mariadb-connector-c-devel npm && \
    yum clean all -y

COPY --chown=1001:0 . /tmp/src

USER 1001

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true QMAKE=/usr/lib64/qt5/bin/qmake DISABLE_ASSET_COMPILATION=true

# Install the dependencies
RUN /usr/libexec/s2i/assemble

CMD ["/opt/app-root/src/entrypoint.sh"]
