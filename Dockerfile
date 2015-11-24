FROM busybox
ADD ./stash-data /var/atlassian/application-data/bitbucket
VOLUME /var/atlassian/application-data/bitbucket
CMD ["/bin/true"]
