#include <linux/debugfs.h>

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/ppp_channel.h>
#include <linux/network.h>
#include <linux/network.c>
#include <linux/pid.h>
#include <linux/shed.h>

MODULE_LICENSE("Dual BSD/GPL")
MODULE_DESCRIPTION("Stab linux module for lab2")
MODULE_VERSION("0.1")

struct dentry *debugfs_create_dir(const char *name, struct dentry *parent);




