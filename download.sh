#!/bin/bash

rm -rvf *-10m.json
mkdir -p build

if [ ! -f build/cb_2017_us_county_5m.shp ]; then
  curl -o build/cb_2017_us_county_5m.zip 'https://www2.census.gov/geo/tiger/GENZ2017/shp/cb_2017_us_county_5m.zip'
  unzip -od build build/cb_2017_us_county_5m.zip cb_2017_us_county_5m.shp cb_2017_us_county_5m.dbf
  chmod a-x build/cb_2017_us_county_5m.*
fi