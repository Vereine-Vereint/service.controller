FROM nginx:alpine

# Copy the HTML and JS files
COPY index.html /usr/share/nginx/html/
COPY redirect.html /usr/share/nginx/html/
COPY reload-check.js /usr/share/nginx/html/

# Copy the nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
