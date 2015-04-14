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
SUGAR_PATH="/var/www/html/sugar"

##
## checking parameters
## 
if [ -z $1 ] || [ -z $2 ] ; then
       
    echo "Script usage : $0 <module_dir> <module_label>" && exit 1
fi
if [ ! -d $SUGAR_PATH/modules/$MODULE_NAME ]; then

    echo "$SUGAR_PATH/modueles/$MODULE_NAME is not an existing module directory" && exit 1
fi

##
## Initialising variable
##
MODULE_NAME=$1
MODULE_LBL=$2
OUTPUT_ZIP="$MODULE_NAME.zip"

# Create destination temp dir
mkdir -p /tmp/$MODULE_NAME/

#if [ ! -d $SUGAR_PATH/modules/$MODULE_NAME/views ]; then
#
#    mkdir  $SUGAR_PATH/modules/$MODULE_NAME/views
#fi

##
## Modify language file so all works good
##
LANG_PATH="$SUGAR_PATH/modules/$MODULE_NAME/language"
for file in `find $LANG_PATH -type f -exec /bin/ls -1 {} \;`; do

    cat "$file" | /bin/grep -q "app_list_strings"
    if [ $? -ne 0 ]; then
        echo -e '\n' >> $file
        echo "\$app_list_strings['moduleList']['$MODULE_NAME'] = '$MODULE_LBL';" >> $file
    else
        sed -i "/moduleList/c\\\$app_list_strings['moduleList']['$MODULE_NAME'] = '$MODULE_LBL';" $file
    fi
done

echo "You are going to create package $OUTPUT_ZIP"

# make sure dest dir is empty
if [ -d /tmp/$MODULE_NAME ]; then
    echo "deleting old sources in /tmp";
    rm -rf /tmp/$MODULE_NAME
    if [ -f /tmp/$MODULE_NAME.zip ]; then
        echo "deleting old zip from /tmp"
        rm /tmp/$MODULE_NAME.zip
    fi
fi
mkdir -p /tmp/$MODULE_NAME/modules

# Copy sources files in destination directiry
cp -R $SUGAR_PATH/modules/$MODULE_NAME /tmp/$MODULE_NAME/modules/$MODULE_NAME

# Create a README.txt if it does not exist and copy it to temp directory
if [ ! -f $SUGAR_PATH/modules/$MODULE_NAME/README.txt ]; then

    touch $SUGAR_PATH/modules/$MODULE_NAME/README.txt
    echo "README.TXT : Please fill this" > $SUGAR_PATH/modules/$MODULE_NAME/README.txt
fi
cp $SUGAR_PATH/modules/$MODULE_NAME/README.txt /tmp/README.txt

# Create a LICENCE.txt if it does not exist and copy it to temp directory
if [ ! -f $SUGAR_PATH/modules/$MODULE_NAME/LICENCE.txt ]; then

    touch $SUGAR_PATH/modules/$MODULE_NAME/LICENCE.txt
     echo "LICENCE.TXT : Please fill this" > $SUGAR_PATH/modules/$MODULE_NAME/LICENCE.txt
fi
cp $SUGAR_PATH/modules/$MODULE_NAME/LICENCE.txt /tmp/$MODULE_NAME//LICENCE.txt


##
## Check if the module has some custom dev from Studio
##
HAS_CUSTOM=0
if [ -d $SUGAR_PATH/custom/modules/$MODULE_NAME ]; then
    HAS_CUSTOM=1
    mkdir -p /tmp/$MODULE_NAME/custom/modules 
    cp -R $SUGAR_PATH/custom/modules/$MODULE_NAME /tmp/$MODULE_NAME/custom/modules/$MODULE_NAME
fi

##
## Check if the module has some extension dev from Studio
##
HAS_EXTENSION=0
if [ -d $SUGAR_PATH/custom/Extension/modules/$MODULE_NAME ]; then
    HAS_EXTENSION=1
    mkdir -p /tmp/$MODULE_NAME/custom/Extension/modules
    cp -R $SUGAR_PATH/custom/Extension/modules/$MODULE_NAME /tmp/$MODULE_NAME/custom/Extension/modules/$MODULE_NAME
fi

COUNT=0
##
## Create Manifest File
##
cat << EOF > /tmp/$MODULE_NAME/manifest.php
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
        $COUNT => 
        array (
          'from' => '<basepath>/modules/$MODULE_NAME',
          'to' => 'modules/$MODULE_NAME',
        ),

EOF

COUNT=$(($COUNT + 1))

if [ ! -z $HAS_CUSTOM ]; then
cat << EOF >> /tmp/$MODULE_NAME/manifest.php
        $COUNT => 
        array (
          'from' => '<basepath>/custom/modules/$MODULE_NAME',
          'to' => 'custom/modules/$MODULE_NAME',
        ),
EOF
COUNT=$(($COUNT + 1))
fi

if [ ! -z $HAS_EXTENSION ]; then
cat << EOF >> /tmp/$MODULE_NAME/manifest.php
        $COUNT => 
        array (
          'from' => '<basepath>/custom/Extension/modules/$MODULE_NAME',
          'to' => 'custom/Extension/modules/$MODULE_NAME',
        ),
EOF
COUNT=$(($COUNT + 1))
fi

cat << EOF >> /tmp/$MODULE_NAME/manifest.php

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
zip -r $OUTPUT_ZIP modules custom manifest.php LICENCE.txt README.txt >> /dev/null
cd -
