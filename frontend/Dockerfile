FROM nginx:1.27-alpine

# Copy the custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static HTML/CSS/JS files
COPY html/ /usr/share/nginx/html/

EXPOSE 80
