#/bin/bash
# Simple Script To Fix phpmyadmin count errors with PHP 7.2

sed -i "s/|\s*\((count(\$analyzed_sql_results\['select_expr'\]\)/| (\1)/g" /usr/share/phpmyadmin/libraries/sql.lib.php
