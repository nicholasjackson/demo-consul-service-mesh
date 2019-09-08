#!/bin/sh

consul config delete -kind service-splitter -name payments
consul config delete -kind service-resolver -name payments
consul config delete -kind service-splitter -name payments-split
consul config delete -kind service-resolver -name payments-split
