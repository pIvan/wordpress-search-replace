# wordpress-search-replace
SQL script used to search and replace URLs in a wordpress project in the migration process

## How to run
- make database backup!
- run `phpmyadmin` and select database
- copy code from SQL script `search-replace.sql`
- paste it to `phpmyadmin` SQL tab
- find two variables  at the bottom of the script and replace them with your url's
```
SET @FIND_URL = 'http://localhost/projects-name/';
SET @REPLACE_URL_WITH = 'https://www.example.com/';
```
- run script (at your own risk)


