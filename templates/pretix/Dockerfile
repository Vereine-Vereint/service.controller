ARG PRETIX_VERSION
FROM pretix/standalone:${PRETIX_VERSION}
USER root
RUN pip3 install pretix-passbook pretix-servicefees prtx-faq pretix-regex-validation
USER pretixuser
RUN cd /pretix/src && make production
