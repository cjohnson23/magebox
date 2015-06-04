server {
    listen *:80;
    server_name magebox.liveoutthere.com;

    root /var/www/html;
    sendfile off;
    index index.php index.html;

    location / {
        try_files $uri $uri/ @handler; ## If missing pass the URI to Magento's front handler
        proxy_read_timeout 300;
    }

    location /api {
	rewrite ^/api/rest /api.php?type=rest last;
	allow 127.0.0.1;
	allow 192.168.1.1; #or whatever your host IP address is.
	deny all;
    }

    ## These locations would be hidden by .htaccess normally
    ## location ^~ /app/                { deny all; }
    ## location ^~ /includes/           { deny all; }
    ## location ^~ /lib/                { deny all; }
    ## location ^~ /media/downloadable/ { deny all; }
    ## location ^~ /pkginfo/            { deny all; }
    ## location ^~ /report/config.xml   { deny all; }
    ## location ^~ /var/                { deny all; }

    location /var/export/ { ## Allow admins only to view export folder
        #auth_basic           "Restricted"; ## Message shown in login window
        #auth_basic_user_file htpasswd; ## See /etc/nginx/htpassword
        #autoindex            on;
    }

    location  /. { ## Disable .htaccess and other hidden files
        return 404;
    }

    location @handler { ## Magento uses a common front handler
        rewrite / /index.php;
    }

    location ~ .php/ { ## Forward paths like /js/index.php/x.js to relevant handler
        rewrite ^(.*.php)/ $1 last;
    }

    location ~ .php$ { ## Execute PHP scripts
        if (!-e $request_filename) { rewrite / /index.php last; } ## Catch 404s that try_files miss
        expires        off; ## Do not cache dynamic content
        fastcgi_pass 127.0.0.1:9000;
	    fastcgi_index index.php;
        fastcgi_read_timeout 150;
	    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_param  MAGE_RUN_CODE default; ## Store code is defined in administration > Configuration > Manage Stores
        fastcgi_param  MAGE_RUN_TYPE store;
        include        /etc/nginx/fastcgi_params; ## See /etc/nginx/fastcgi_params
	    fastcgi_buffers 16 16k;
	    fastcgi_buffer_size 32k;
	    root  /var/www/html;
    }
}
