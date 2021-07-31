#!/bin/bash

# example usage
# sh create-logos.sh provider ./provider-large.png


NAME=$1
SOURCE_IMAGE=$2

OUT_FILE=$NAME.png

echo "NAME: $NAME"
echo "SOURCE IMAGE: $SOURCE_IMAGE"

resize() {
        RESIZE_TO=$1
        OUT_FOLDER=$2

        mkdir -p $OUT_FOLDER

        convert -geometry x$1 $SOURCE_IMAGE $OUT_FOLDER/$OUT_FILE
        echo "resizing $SOURCE_IMAGE to x$1 ==> result - $OUT_FOLDER/$OUT_FILE [`identify -format "%wx%h" $OUT_FOLDER/$OUT_FILE`]"
}


echo "Creating logos"

resize 20 ./web/logos/20
resize 20 ./web/logos/21
resize 30 ./web/logos/31
resize 40 ./web/logos/42
resize 60 ./web/logos/63
resize 80 ./web/logos/83
