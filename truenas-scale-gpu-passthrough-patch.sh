#!/usr/bin/env bash
#
# Removes host GPU requirement from TrueNAS Scale to allow a single GPU to be passed through to a VM
#
# Based on https://github.com/Jahfry/Miscellaneous/blob/main/TrueNAS_Scale_driverctl.md
#

BACKUP_FILES="/usr/share/truenas/webui/609-es2015.f059fa779e0b83eaa150.js /usr/share/truenas/webui/609-es5.f059fa779e0b83eaa150.js /usr/share/truenas/webui/715-es2015.b3b1eb8aed99ad4e4035.js /usr/share/truenas/webui/715-es5.b3b1eb8aed99ad4e4035.js /usr/lib/python3/dist-packages/middlewared/plugins/system_advanced/config.py"

# Make backups of originals
for f in $BACKUP_FILES; do
	target="${f}.orig"
	if [[ ! -f "$target" ]]; then
		cp -a "$f" "$target"
	fi
done

# Patch the files
perl -i -pe 's|\Qif([...t].length>=(null===(i=this.availableGpus)\E|if([...t].length>(null===(i=this.availableGpus)|g' /usr/share/truenas/webui/609-es2015.f059fa779e0b83eaa150.js
perl -i -pe 's|\Qif(t(a).length>=(null===(o=e.availableGpus)\E|if(t(a).length>(null===(o=e.availableGpus)|g' /usr/share/truenas/webui/609-es5.f059fa779e0b83eaa150.js
perl -i -pe 's|\Q{name:"gpus"});if(i.length&&i.length>=o.options.length)\E|{name:"gpus"});if(i.length&&i.length>o.options.length)|g' /usr/share/truenas/webui/715-es2015.b3b1eb8aed99ad4e4035.js
perl -i -pe 's|\Q{name:"gpus"});if(r.length&&r.length>=c.options.length)\E|{name:"gpus"});if(r.length&&r.length>c.options.length)|g' /usr/share/truenas/webui/715-es5.b3b1eb8aed99ad4e4035.js
perl -i -pe 's|\Qif len(available - provided) < 1|if False and len(available - provided) < 1|g' /usr/lib/python3/dist-packages/middlewared/plugins/system_advanced/config.py

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
