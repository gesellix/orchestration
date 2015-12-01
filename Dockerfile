FROM alpine
RUN mkdir -p /var/atlassian/application-data/bitbucket/shared
COPY ./bitbucket.properties /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
VOLUME /var/atlassian/application-data/bitbucket
CMD ["/bin/true"]
