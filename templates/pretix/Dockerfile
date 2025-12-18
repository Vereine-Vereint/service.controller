FROM pretix/standalone:2025.9.0
USER root
RUN pip3 install pretix-passbook pretix-servicefees prtx-faq pretix-regex-validation
USER pretixuser
RUN cd /pretix/src && make production
