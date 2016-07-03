#! /bin/sh

set -e

CONF=$SNAP_DATA/minidlna.conf
MYIP="$(cat $SNAP_DATA/.ip)"

# function to turn yaml into variables
parse_yaml()
{
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_-]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   gawk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# get the piped input and store it in a tmpfile
while IFS= read -r LINE; do
    if [ ! "$(id -u)" = "0" ]; then
        echo -n "permission denied (try sudo)"
        exit 1
    fi
    printf "%s\n" "$LINE" >>$SNAP_DATA/.tmp.yaml
done

# if we have permissions, write the different configs
if [ "$(id -u)" = "0" ]; then

    touch $SNAP_DATA/.tmp.yaml
    [ -e $SNAP_DATA/config.yaml ] || \
        cp $SNAP/default.yaml $SNAP_DATA/config.yaml

    # get all the vars from yaml
    eval $(parse_yaml $SNAP_DATA/config.yaml)
    eval $(parse_yaml $SNAP_DATA/.tmp.yaml)

    cat << EOF >$SNAP_DATA/config.yaml
config:
  dlna:
    port: $config_dlna_port
    name: $config_dlna_name
    showip: $config_dlna_showip
    interval: $config_dlna_interval
  webdav:
    port: $config_webdav_port
EOF

    cat << EOF >$CONF
# port for HTTP (descriptions, SOAP, media transfer) traffic
port=$config_dlna_port

# network interfaces to serve, comma delimited
#network_interface=eth0

# specify the user account name or uid to run as
#user=jmaggard

# set this to the directory you want scanned.
# * if you want multiple directories, you can have multiple media_dir
# * if you want to restrict a media_dir to specific content types, you
#   can prepend the types, followed by a comma, to the directory:
#   + "A" for audio  (eg. media_dir=/var/lib/apps/upnp-server.sideload/IGbAaXdXRDVT/Media
#   + "V" for video  (eg. media_dir=/var/lib/apps/upnp-server.sideload/IGbAaXdXRDVT/Media
#   + "P" for images (eg. media_dir=/var/lib/apps/upnp-server.sideload/IGbAaXdXRDVT/Media
#   + "PV" for pictures and video (eg. media_dir=/var/lib/apps/upnp-server.sideload/IGbAaXdXRDVT/Media
media_dir=$SNAP_DATA/Media

# set this to merge all media_dir base contents into the root container
# note: the default is no
#merge_media_dirs=no

# set this if you want to customize the name that shows up on your clients
EOF

    DLNANAME="$config_dlna_name"
    case $config_dlna_showip in
        [Tt][Rr][Uu][Ee]|[Yy]|[Yy][Ee][Ss])
          DLNANAME="$DLNANAME $MYIP"
        ;;
    esac
    echo "friendly_name=$DLNANAME" >>$CONF

    cat << EOF >>$CONF

# set this if you would like to specify the directory where you want MiniDLNA to store its database and album art cache
db_dir=$SNAP_DATA/cache

# set this if you would like to specify the directory where you want MiniDLNA to store its log file
log_dir=$SNAP_DATA/log

# set this to change the verbosity of the information that is logged
# each section can use a different level: off, fatal, error, warn, info, or debug
#log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo=warn

# this should be a list of file names to check for when searching for album art
# note: names should be delimited with a forward slash ("/")
album_art_names=Cover.jpg/cover.jpg/AlbumArtSmall.jpg/albumartsmall.jpg/AlbumArt.jpg/albumart.jpg/Album.jpg/album.jpg/Folder.jpg/folder.jpg/Thumb.jpg/thumb.jpg

# set this to no to disable inotify monitoring to automatically discover new files
# note: the default is yes
inotify=yes

# set this to yes to enable support for streaming .jpg and .mp3 files to a TiVo supporting HMO
enable_tivo=no

# set this to strictly adhere to DLNA standards.
# * This will allow server-side downscaling of very large JPEG images,
#   which may hurt JPEG serving performance on (at least) Sony DLNA products.
strict_dlna=no

# default presentation url is http address on port 80
#presentation_url=http://www.mylan/index.php

# notify interval in seconds. default is 895 seconds.
notify_interval=$config_dlna_interval

# serial and model number the daemon will report to clients
# in its XML description
serial=12345678
model_number=1

# specify the path to the MiniSSDPd socket
minissdpdsocket=$SNAP_DATA/minissdpd.sock

# use different container as root of the tree
# possible values:
#   + "." - use standard container (this is the default)
#   + "B" - "Browse Directory"
#   + "M" - "Music"
#   + "V" - "Video"
#   + "P" - "Pictures"
#   + Or, you can specify the ObjectID of your desired root container (eg. 1$F for Music/Playlists)
# if you specify "B" and client device is audio-only then "Music/Folders" will be used as root
root_container=B

# always force SortCriteria to this value, regardless of the SortCriteria passed by the client
#force_sort_criteria=+upnp:class,+upnp:originalTrackNumber,+dc:title

# maximum number of simultaneous connections
# note: many clients open several simultaneous connections while streaming
#max_connections=50
EOF

    chmod 0600 $CONF
    # flush the tmpfile
    >$SNAP_DATA/.tmp.yaml
fi

cat $SNAP_DATA/config.yaml
