# get name of cwd
cd `dirname $0`

IPUF=~/Documents/WaveMetrics/Igor\ Pro\ 7\ User\ Files

cp -r "macXOP/Igor Extensions (64-bit)/" "$IPUF/Igor Extensions (64-bit)"
cp -r "Igor Procedures/" "$IPUF/Igor Procedures"
cp -r "User Procedures/" "$IPUF/User Procedures"