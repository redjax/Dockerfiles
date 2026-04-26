ARG TRIVY_TAG=0.70.0

FROM aquasec/trivy:${TRIVY_TAG}

WORKDIR /scan

ENTRYPOINT ["trivy"]
CMD ["--help"]
