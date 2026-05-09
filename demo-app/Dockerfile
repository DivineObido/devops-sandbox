FROM nginx:alpine

RUN mkdir -p /etc/nginx/conf.d

RUN rm /etc/nginx/conf.d/default.conf

COPY health.conf /etc/nginx/conf.d/health.conf

EXPOSE 80