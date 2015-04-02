#!/bin/bash

##
## author : Jérémy Blanc
## company : smile
## email : jeremy.blanc@smile.fr
## files : create_module_package_V2.sh
## This script allow you to create the manifest.php for
## a module directory and create a Zip file in /tmp

##
## Configuring the script
##
PATH="/var/www/html/sugar"

##
## checking parameters
## 
if [ -z $1 ] || [ -z $2 ] ; then
       
    echo "Script usage : $0 <module_dir> <module_label>" && exit 1
fi
if [ ! -d $PATH/modules/$MODULE_NAME ]; then

    echo "$PATH/modueles/$MODULE_NAME is not an existing module directory" && exit 1
fi

##
## Initialising variable
##
MODULE_NAME=$1
MODULE_LBL=$2
OUTPUT_ZIP="$MODULE_NAME.zip"

# Create destination temp dir
/bin/mkdir -p /tmp/$MODULE_NAME/

#if [ ! -d $PATH/modules/$MODULE_NAME/views ]; then
#
#    /bin/mkdir  $PATH/modules/$MODULE_NAME/views
#fi

##
## Modify language file so all works good
##
LANG_PATH="$PATH/modules/$MODULE_NAME/language"
for file in `/usr/bin/find $LANG_PATH -type f -exec /bin/ls -1 {} \;`; do

    /bin/cat "$file" | /bin/grep -q "app_list_strings"
    if [ $? -ne 0 ]; then
        echo -e '\n' >> $file
        echo "\$app_list_strings['moduleList']['$MODULE_NAME'] = '$MODULE_LBL';" >> $file
    else
        /bin/sed -i "/moduleList/c\\\$app_list_strings['moduleList']['$MODULE_NAME'] = '$MODULE_LBL';" $file
    fi
done

echo "You are going to create package $OUTPUT_ZIP"

# make sure dest dir is empty
if [ -d /tmp/$MODULE_NAME ]; then
    echo "deleting old sources in /tmp";
    /bin/rm -rf /tmp/$MODULE_NAME
    if [ -f /tmp/$MODULE_NAME.zip ]; then
        echo "deleting old zip from /tmp"
        /bin/rm /tmp/$MODULE_NAME.zip
    fi
fi
/bin/mkdir -p /tmp/$MODULE_NAME/modules

# Copy sources files in destination directiry
/bin/cp -R $PATH/modules/$MODULE_NAME /tmp/$MODULE_NAME/modules/$MODULE_NAME

# Create a README.txt if it does not exist and copy it to temp directory
if [ ! -f $PATH/modules/$MODULE_NAME/README.txt ]; then

    /usr/bin/touch $PATH/modules/$MODULE_NAME/README.txt
    echo "README.TXT : Please fill this" > $PATH/modules/$MODULE_NAME/README.txt
fi
/bin/cp $PATH/modules/$MODULE_NAME/README.txt /tmp/README.txt

# Create a LICENCE.txt if it does not exist and copy it to temp directory
if [ ! -f $PATH/modules/$MODULE_NAME/LICENCE.txt ]; then

    /usr/bin/touch $PATH/modules/$MODULE_NAME/LICENCE.txt
     echo "LICENCE.TXT : Please fill this" > $PATH/modules/$MODULE_NAME/LICENCE.txt
fi
/bin/cp $PATH/modules/$MODULE_NAME/LICENCE.txt /tmp/$MODULE_NAME//LICENCE.txt


##
## Check if the module has some custom dev from Studio
##
HAS_CUSTOM=0
if [ -d $PATH/custom/modules/$MODULE_NAME ]; then
    HAS_CUSTOM=1
    /bin/mkdir -p /tmp/$MODULE_NAME/custom/modules
    /bin/cp -R $PATH/custom/modules/$MODULE_NAME /tmp/$MODULE_NAME/custom/modules/$MODULE_NAME
fi

##
## Create Manifest File
##
/bin/cat << EOF > /tmp/$MODULE_NAME/manifest.php
<?php

\$manifest = array(
    0 => 
    array (
        'acceptable_sugar_versions' =>
        array (
            0 => '',
        ),
    ),
    1 => 
    array (
        'acceptable_sugar_flavors' =>
        array (
            0 => 'CE',
            1 => 'PRO',
            2 => 'ENT',
        ),
    ),
    'readme'           => '',
    'key'              => 'al666',
    'author'           => '$MODULE_NAME',
    'description'      => '$MODULE_NAME',
    'icon'             => '',
    'is_uninstallable' => true,
    'name'             => '$MODULE_LBL',
    'published_date'   => '2015-03-30 15:47:03',
    'type'             => 'module',
    'version'          => 1427730424,
    'remove_tables'    => 'prompt'
);

\$installdefs = array (
    'id' => '$MODULE_NAME',
    'beans' => 
        array(
            0 =>
            array (
                'module' => '$MODULE_NAME',
                'class'  => '$MODULE_NAME',
                'path'   => 'modules/$MODULE_NAME/$MODULE_NAME.php',
                'tab'    => true
            ),
        ),
    'layoutdefs' => 
        array (
        ),
    'relationships' => 
        array (
        ),
    'copy' => 
      array (
        0 => 
        array (
          'from' => '<basepath>/modules/$MODULE_NAME',
          'to' => 'modules/$MODULE_NAME',
        ),

EOF

if [ -z HAS_CUSTOM ]; then
/bin/cat << EOF >> /tmp/$MODULE_NAME/manifest.php
        1 => 
        array (
          'from' => '<basepath>/custom/modules/$MODULE_NAME',
          'to' => 'custom/modules/$MODULE_NAME',
        ),
EOF
fi

/bin/cat << EOF >> /tmp/$MODULE_NAME/manifest.php

      ),
    'language' =>
    array (
        0 =>
        array ( 
            'from' => '<basepath>/modules/$MODULE_NAME/language/en_us.lang.php',
            'to_module' => 'application',
            'language' => 'en_us'
        ),
        1 =>
        array ( 
            'from' => '<basepath>/modules/$MODULE_NAME/language/fr_FR.lang.php',
            'to_module' => 'application',
            'language' => 'fr_FR'
        ),
    ),

);
?>
EOF

##
## Create ZIp FIle
##
cd /tmp/$MODULE_NAME
/usr/bin/zip -r $OUTPUT_ZIP modules custom manifest.php LICENCE.txt README.txt >> /dev/null
cd -
