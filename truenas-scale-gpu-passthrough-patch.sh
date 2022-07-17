#!/usr/bin/env bash
#
# Removes host GPU requirement from TrueNAS Scale to allow a single GPU to be passed through to a VM
#
# Based on https://github.com/Jahfry/Miscellaneous/blob/main/TrueNAS_Scale_driverctl.md
#

# Find relevant files in this build
THIS_AVAILABLE_GPUS=$(grep -rnl 'this.availableGpus' /usr/share/truenas/webui | grep -v .map)
E_AVAILABLE_GPUS=$(grep -rnl 'e.availableGpus' /usr/share/truenas/webui)
NAME_GPUS=$(grep -rnl 'name:"gpus"' /usr/share/truenas/webui)
PY_CONFIG="/usr/lib/python3/dist-packages/middlewared/plugins/system_advanced/config.py"
BACKUP_FILES="$THIS_AVAILABLE_GPUS $E_AVAILABLE_GPUS $NAME_GPUS $PY_CONFIG"

# Make backups of originals
for f in $BACKUP_FILES; do
  target="${f}.orig"
  if [[ ! -f "$target" ]]; then
    cp -a "$f" "$target"
  fi
done

# Patch the files
for f in $THIS_AVAILABLE_GPUS; do
  perl -i -pe 's|\Qif([...t].length>=(null===(i=this.availableGpus)\E|if([...t].length>(null===(i=this.availableGpus)|g' "$f"
done

for f in $E_AVAILABLE_GPUS; do
  perl -i -pe 's|\Qif(t(a).length>=(null===(o=e.availableGpus)\E|if(t(a).length>(null===(o=e.availableGpus)|g' "$f"
done

for f in $NAME_GPUS; do
  perl -i -pe 's|\Q{name:"gpus"});if(i.length&&i.length>=o.options.length)\E|{name:"gpus"});if(i.length&&i.length>o.options.length)|g' "$f"
done

perl -i -pe 's|\Qif len(available - provided) < 1|if False and len(available - provided) < 1|g' "$PY_CONFIG"

# Show diffs
for f in $BACKUP_FILES; do
	orig="${f}.orig"
	echo
	echo "--- Changes for $(basename $f) ---"
	diff "$orig" "$f"
	echo
done

# Clear compile cache for Python
rm -rf /usr/lib/python3/dist-packages/middlewared/plugins/system_advanced/__pycache__

# Restart services
service middlewared restart
service nginx restart
