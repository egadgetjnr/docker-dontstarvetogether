#!/usr/bin/env bash

if [ $# -eq 0 ]
then
STORAGE_ROOT="/var/lib/dsta"
CONF_DIR="server"

# Update game and mods.
if [ "$UPDATE_ON_BOOT" = "true" ]; then
  update.sh
fi

# Create data directory.
mkdir -p "$STORAGE_ROOT/$CONF_DIR/save/" \
  && chown -R steam:steam "$STORAGE_ROOT/$CONF_DIR/"

# Create the settings.ini file.
FILE_SETTINGS="$STORAGE_ROOT/$CONF_DIR/settings.ini"
if [ ! -f $FILE_SETTINGS ]; then
  if [ -z "$DEFAULT_SERVER_NAME" ]; then
    selectRandomLine(){
      mapfile list < $1
      echo ${list[$RANDOM % ${#list[@]}]}
    }

    DEFAULT_SERVER_NAME="`selectRandomLine /usr/local/dsta/adjectives.txt` `selectRandomLine /usr/local/dsta/names.txt`"
    echo "'$DEFAULT_SERVER_NAME' has been set as the server's name."
  fi

cat <<- EOF > $FILE_SETTINGS
	[network]
	default_server_name = $SERVER_NAME_PREFIX $DEFAULT_SERVER_NAME
	default_server_description = $DEFAULT_SERVER_DESCRIPTION
	server_port = $SERVER_PORT
	server_password = $SERVER_PASSWORD
	offline_server = $OFFLINE_SERVER
	max_players = $MAX_PLAYERS
	whitelist_slots = $WHITELIST_SLOTS
	pvp = $PVP
	game_mode = $GAME_MODE
	server_intention = $SERVER_INTENTION
	enable_autosaver = $ENABLE_AUTOSAVER
	tick_rate = $TICK_RATE
	connection_timeout = $CONNECTION_TIMEOUT
	enable_vote_kick = $ENABLE_VOTE_KICK
	pause_when_empty = $PAUSE_WHEN_EMPTY
	steam_authentication_port = $STEAM_AUTHENTICATION_PORT
	steam_master_server_port = $STEAM_MASTER_SERVER_PORT
	steam_group_id = $STEAM_GROUP_ID
	steam_group_only = $STEAM_GROUP_ONLY
	steam_group_admins = $STEAM_GROUP_ADMINS

	[account]
	server_token = $SERVER_TOKEN

	[misc]
	console_enabled = $CONSOLE_ENABLED
	autocompiler_enabled = $AUTOCOMPILER_ENABLED
	mods_enabled = $MODS_ENABLED

	[shard]
	shard_enable = $SHARD_ENABLE
	shard_name = $SHARD_NAME
	shard_id = $SHARD_ID
	is_master = $IS_MASTER
	master_ip = $MASTER_IP
	master_port = $MASTER_PORT
	bind_ip = $BIND_IP
	cluster_key = $CLUSTER_KEY

	[steam]
	disablecloud = $DISABLECLOUD
EOF
chown steam:stem $FILE_SETTINGS
fi

# Create the adminlist.txt file.
FILE_ADMINLIST="$STORAGE_ROOT/$CONF_DIR/save/adminlist.txt"
if [ -n "$ADMINLIST" ] && [ ! -f $FILE_ADMINLIST ]; then
  echo $ADMINLIST | tr , '\n' > $FILE_ADMINLIST
fi

# Create the whitelist.txt file.
FILE_WHITELIST="$STORAGE_ROOT/$CONF_DIR/save/whitelist.txt"
if [ -n "$WHITELIST" ] && [ ! -f $FILE_WHITELIST ]; then
  echo $WHITELIST | tr , '\n' > $FILE_WHITELIST
fi

# Create the blocklist.txt file.
FILE_BLOCKLIST="$STORAGE_ROOT/$CONF_DIR/save/blocklist.txt"
if [ -n "$BLOCKLIST" ] && [ ! -f $FILE_BLOCKLIST ]; then
  echo $BLOCKLIST | tr , '\n' > $FILE_BLOCKLIST
fi

# Configure custom world generation and presets.
FILE_WORLD="$STORAGE_ROOT/$CONF_DIR/worldgenoverride.lua"
if [ -n "$WORLD_OVERRIDES" ] && [ ! -f $FILE_WORLD ]; then
  echo "$WORLD_OVERRIDES" > $FILE_WORLD
elif [ -n "$WORLD_PRESET" ] && [ ! -f $FILE_WORLD ]; then
cat <<- EOF > $FILE_WORLD
	return {
	    override_enabled = true,
	    preset = "$WORLD_PRESET",
	}
EOF
fi

# Install mods.
FILE_MODS="/opt/steam/DoNotStarveTogether/mods/dedicated_server_mods_setup.lua"
if [ -n "$MODS" ]; then

  > $FILE_MODS

  IFS=","
  for MOD in $MODS; do
    echo "ServerModSetup(\"$MOD\")" >> $FILE_MODS
  done
fi

# Configure Mods.
FILE_MODS_OVERRIDES="$STORAGE_ROOT/$CONF_DIR/modoverrides.lua"
if [ -n "$MODS" ] && [ -n "$MODS_OVERRIDES" ] && [ ! -f $FILE_MODS_OVERRIDES ]; then
  echo "$MODS_OVERRIDES" > $FILE_MODS_OVERRIDES
elif [ -n "$MODS" ] && [ ! -f $FILE_MODS_OVERRIDES ]; then
  echo "return {" >> $FILE_MODS_OVERRIDES

  for MOD in $MODS; do
    echo "[\"workshop-$MOD\"] = { enabled = true }," >> $FILE_MODS_OVERRIDES
  done

  echo "}" >> $FILE_MODS_OVERRIDES
fi

# Run the DST executable.
exec gosu steam ./dontstarve_dedicated_server_nullrenderer \
  -console \
  -persistent_storage_root "$STORAGE_ROOT" \
  -conf_dir "$CONF_DIR" \
  "$@"
else
  exec $@
fi
