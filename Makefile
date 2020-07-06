.PHONY: dist

default: build \
	build/counties/raw/cb_2017_us_county_5m.shp \
	build/counties/processed/state-level/06.json \
	build/counties/processed/county-level/%.json \
	build/roads/raw/ne_10m_roads_north_america.shp \
	build/roads/processed/state-level/06.json \
	build/roads/processed/county-level/%.json \
	build/places/processed/state-level/06.json \
	build/places/processed/county-level/%.json \
	build/combined/%.json \
	build/combined/075.json \
	build/combined/los-angeles-countywide-statistical-areas.json \
	build/combined/los-angeles-countywide-statistical-areas-contiguous.json \
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

build/counties/raw/cb_2017_us_county_5m.shp:
	unzip input/cb_2017_us_county_5m -d build/counties/raw

build/counties/processed/state-level/06.json:
	mapshaper build/counties/raw/cb_2017_us_county_5m.shp \
		-filter 'STATEFP == "06"' \
		-o format=geojson build/counties/processed/state-level/06.json

build/counties/processed/county-level/%.json:
	mapshaper  build/counties/processed/state-level/06.json \
		-split COUNTYFP \
		-o format=geojson ./build/counties/processed/county-level/

build/roads/raw/ne_10m_roads_north_america.shp:
	unzip input/ne_10m_roads_north_america.zip -d build/roads/raw

build/roads/processed/state-level/06.json:
	mapshaper build/roads/raw/ne_10m_roads_north_america.shp \
		-filter 'state == "California"' \
		-o - format=geojson | \
	mapshaper - \
		-filter '"Freeway,Primary,Secondary,Tollway,Other Paved".indexOf(type) > -1' \
		-o format=geojson build/roads/processed/state-level/06.json

build/roads/processed/county-level/%.json:
	find build/counties/processed/county-level/ -name '*.json' -print0 | \
	sed --expression='s|build/counties/processed/county-level/||g' | \
	xargs -0 -I % mapshaper build/roads/processed/state-level/06.json \
		-clip build/counties/processed/county-level/% \
		-filter-fields type \
		-o build/roads/processed/county-level/% format=geojson

build/places/processed/state-level/06.json:
	mapshaper input/acs2018_5yr_B01003_16000US0637134.geojson \
		-points \
		-filter-fields geoid,name,B01003001 \
		-rename-fields population=B01003001 \
		-o format=geojson build/places/processed/state-level/06.json

build/places/processed/county-level/%.json:
	find build/counties/processed/county-level/ -name '*.json' -print0 | \
	sed --expression='s|build/counties/processed/county-level/||g' | \
	xargs -0 -I % mapshaper build/places/processed/state-level/06.json \
		-clip build/counties/processed/county-level/% \
		-o build/places/processed/county-level/% format=geojson

build/combined/%.json:
	find build/counties/processed/county-level/ -name '*.json' -print0 | \
	sed --expression='s|build/counties/processed/county-level/||g' | \
	xargs -0 -I % mapshaper -i build/counties/processed/county-level/% \
		build/roads/processed/county-level/% \
		build/places/processed/county-level/% \
		combine-files \
		-rename-layers county,roads,places \
		-o ./build/combined/% format=topojson
	rm build/combined/075.json

build/combined/075.json:
	mapshaper input/san-francisco.shp -o format=geojson input/san-francisco.json
	mapshaper -i input/san-francisco.json \
		build/roads/processed/county-level/075.json \
		build/places/processed/county-level/075.json \
		combine-files \
		-rename-layers county,roads,places \
		-o ./build/combined/075.json format=topojson

build/combined/los-angeles-countywide-statistical-areas.json:
	mapshaper input/los-angeles-countywide-statistical-areas.json -simplify 10% -o input/los-angeles-countywide-statistical-areas-simplified.json
	mapshaper -i input/los-angeles-countywide-statistical-areas-simplified.json \
		build/roads/processed/county-level/037.json \
		build/places/processed/county-level/037.json \
		combine-files \
		-rename-layers county,roads,places \
		-o ./build/combined/los-angeles-countywide-statistical-areas.json format=topojson

build/combined/los-angeles-countywide-statistical-areas-contiguous.json:
	mapshaper -i input/los-angeles-countywide-statistical-areas-simplified-contiguous.json \
		build/roads/processed/county-level/037.json \
		build/places/processed/county-level/037.json \
		combine-files \
		-rename-layers county,roads,places \
		-o ./build/combined/los-angeles-countywide-statistical-areas-contiguous.json format=topojson

dist:
	cp build/combined/* output/

clean:
	rm -rf build/