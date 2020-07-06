.PHONY: dist

default: build \
	build/counties/raw/cb_2017_us_county_5m.shp \
	build/counties/processed/state-level/06.json \
	build/counties/processed/county-level/%.json \
	build/roads/raw/ne_10m_roads_north_america.shp \
	build/roads/processed/state-level/06.json \
	build/roads/processed/county-level/%.json \
	dist

build:
	mkdir -p build/counties
	mkdir -p build/counties/raw
	mkdir -p build/counties/processed/state-level/
	mkdir -p build/counties/processed/county-level/
	mkdir -p build/roads
	mkdir -p build/roads/raw
	mkdir -p build/roads/processed/state-level/
	mkdir -p build/roads/processed/county-level/
	mkdir -p build/places/processed/state-level/
	mkdir -p build/places/processed/county-level/
	mkdir -p build/combined/

build/roads/raw/ne_10m_roads_north_america.shp:
	unzip input/ne_10m_roads_north_america.zip -d build/roads/raw

build/roads/processed/state-level/06.json:
	mapshaper build/roads/raw/ne_10m_roads_north_america.shp \
		-filter 'state == "California"' \
		-o - format=geojson | \
	mapshaper - \
		-filter '"Freeway,Primary,Secondary,Tollway".indexOf(type) > -1' \
		-o format=geojson build/roads/processed/state-level/06.json

build/roads/processed/county-level/%.json:
	find build/counties/processed/county-level/ -name '*.json' -print0 | \
	sed --expression='s|build/counties/processed/county-level/||g' | \
	xargs -0 -I % mapshaper build/roads/processed/state-level/06.json \
		-clip build/counties/processed/county-level/% \
		-filter-fields type \
		-o build/roads/processed/county-level/% format=geojson

dist:
	cp build/combined/* output/

clean:
	rm -rf build/