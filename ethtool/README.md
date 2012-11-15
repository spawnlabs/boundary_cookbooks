## ethtool.d

The ifup-ethtool script provides a means to configure network interfaces with ethtool when the interface is started up. This script reads in a yaml formated config file from `/etc/ethtool.d/IFACE.conf`, where IFACE is the environment variable of the interface being started provided by run-parts or whatever. It then runs the generate ethtool commands described in the config. The ifup-ethtool script can be run with `--test-mode` to force it to not make any changes and simply print out the generated commands.

This cookbook also includes a template file for generating the ethtool configs from attributes.

### Example

Attribute for this example node:

    set[:ethtool][:interfaces][:eth0][:coalesce][:'rx-usecs'] = 1

The above attribute results in the following config file via the ethtool_configs recipe:

`/etc/ethtool.d/eth0.conf`:

    coalesce:
      rx-usecs: 1

This config will produce the following command being run on interface startup:

    ethtool --coalesce eth0 rx-usecs 1