ARG TRIVY_TAG=latest

FROM aquasec/trivy:${TRIVY_TAG}

WORKDIR /scan

ENTRYPOINT ["trivy"]
CMD ["--help"]
