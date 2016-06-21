#!/bin/sh -x

#### WARNING: Only use this if you want the latest version of all attached content views. If you dont, this will not be happy for you!


# set $ORGANIZATION in environment to override the default
[ -z "$ORGANIZATION" ] && echo "Set \$ORGANIZATION in environment" && exit

# set $COMPOSITE_VIEW in environment!!
[ -z "$COMPOSITE_VIEW" ] && echo "Set \$COMPOSITE_VIEW in environment" && exit


latest_content_views=()

## First we look at the composite view. Since a composite view only contains content views, we want to get a list of all the currently
## attached versions of content views

current_cvs=$(hammer content-view info --organization ${ORGANIZATION} --name ${COMPOSITE_VIEW} | awk 'BEGIN { found=0 }; /^Components:/ { found=1 }; /^Activation/ { found=0 }; $2=="ID:" { if (found == 1) print $3 }')

for current_cv in ${current_cvs};
do
  ## Then we want to find what Content view that version belongs to
  parent_cv=$(hammer content-view version info --id ${current_cv} | awk '/Content View ID/ { print $4 }')
  ## And then find the latest version released in that content view and add it to the latest_content_views array
  latest_content_views+=($(hammer content-view info --organization ${ORGANIZATION} --id ${parent_cv} | awk 'BEGIN { id=0; found=0 }; /^Versions:/ { found=1 }; /^Components:/ { found=0 }; $2=="ID:" { if (found == 1) id=$3 }; END { print id };'))
done

## Then we update the content view with all of these released versions
hammer content-view update --organization ${ORGANIZATION} --name ${COMPOSITE_VIEW} --component-ids=$(printf "%s\n" "${latest_content_views[@]}" | paste -d, -s)

## Now publish the composite view
hammer content-view publish --organization ${ORGANIZATION} --name ${COMPOSITE_VIEW}



## For reference here is the horrible one liner i made before breaking this into a script:
# hammer content-view update --organization ${ORGANIZATION} --name ${COMPOSITE_VIEW} --component-ids=$(for curcv in $(hammer content-view info --organization ${ORGANIZATION} --name ${COMPOSITE_VIEW} | awk 'BEGIN { found=0 }; /^Components:/ {found=1}; /^Activation/ {found=0}; $2=="ID:" { if (found == 1) print $3 }'); do parcv=$(hammer content-view version info --id ${curcv} | awk '/Content View ID/ { print $4 }'); echo $(hammer content-view info --organization ${ORGANIZATION} --id ${parcv} | awk 'BEGIN { id=0; found=0 }; /^Versions:/ { found=1 }; /^Components:/ {found=0}; $2=="ID:" { if (found == 1) id=$3 }; END { print id };'); done | paste -d, -s)