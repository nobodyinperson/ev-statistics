#!/usr/bin/make -f

# include make-utils
MAKE_UTILS_PATH = make-utils
MAKE_UTILS_INCLUDES = $(wildcard $(realpath $(MAKE_UTILS_PATH))/*.mk)
ifeq ($(strip $(MAKE_UTILS_INCLUDES)),)
$(error no include files found in $(MAKE_UTILS_PATH))
endif
include $(MAKE_UTILS_INCLUDES) # include the files

### settings ###
OVERVIEW_PAGE_URL = http://www.feuerwehr-aumuehle.de/wopre/alle-einsaetze/alle-einsaetze-2
OVERVIEW_PAGE_LINKS_XPATH = "//table[@class='einsatzverwaltung-reportlist']//a/@href"
OVERVIEW_PAGE_DATE_XPATH = "//table[@class='einsatzverwaltung-reportlist']//td[@class='einsatz-column-date']/text()"
# where to deploy the plot files on 'make deploy'
# You can also specify this on the command line:
# make deploy DEPLOY_DIR=/whatever/path/to/deploy
DEPLOY_DIR = # empty by default. Raises an error on 'make deploy'

# extensions
HTML = html
TMP = tmp
LIST = list
MK = mk
CSV = csv
PNG = png

# directories
HTML_DIR = html
DATA_DIR = data
DEPS_DIR = deps
PLOTS_DIR = plots
SCRIPTS_DIR = scripts
PLOT_SCRIPTS_DIR = $(SCRIPTS_DIR)/plots
TEMP_DIRS = $(HTML_DIR) $(DEPS_DIR) $(PLOTS_DIR) $(DATA_DIR)

# files
OVERVIEW_PAGE_FILE = $(HTML_DIR)/overview.$(HTML)
LINKLIST_FILE = $(HTML_DIR)/linklist.$(LIST)
SINGLE_PAGES_DEP_FILE = $(DEPS_DIR)/single-pages.$(MK)
DATA_FILE_RAW = $(DATA_DIR)/all-data-raw.$(CSV)
DATA_FILE_SANE = $(DATA_DIR)/all-data-sane.$(CSV)
AVAILABLE_YEARS_DEP_FILE = $(DEPS_DIR)/available-years.$(MK)

# scripts
FIND_XPATH = $(SCRIPTS_DIR)/find-xpath.py
SINGLE_PAGE_DATA_EXTRACTOR = $(SCRIPTS_DIR)/extract-data-from-single-page.py
SINGLE_PAGES_DEP_FILE_CREATOR = $(SCRIPTS_DIR)/linklist-to-targets.pl
CSV_CONCATENATOR = $(SCRIPTS_DIR)/concatenate-csv-files.R
DATA_SANITIZER = $(SCRIPTS_DIR)/data-sanitizer.R
YEARS_EXTRACTOR = $(SCRIPTS_DIR)/years-extractor.R

# plot scripts
PLOT_SCRIPTS_FIND_CMD = find $(PLOT_SCRIPTS_DIR) -maxdepth 1 -type f -executable
PLOT_SCRIPTS = $(shell $(PLOT_SCRIPTS_FIND_CMD)) # executable plotscripts
PLOT_NAMES = $(basename $(notdir $(PLOT_SCRIPTS))) # only the names

###############
### targets ###
###############
DEFAULT_TARGET_NAME = all
.PHONY: $(DEFAULT_TARGET_NAME)
$(DEFAULT_TARGET_NAME): $(DATA_FILE_SANE)

# download overview page
$(OVERVIEW_PAGE_FILE): | $(patsubst %/,%,$(dir $(OVERVIEW_PAGE_FILE)))
	$(call download_url_to_file,$(OVERVIEW_PAGE_URL),$@)

# extract linklist from overview page
$(LINKLIST_FILE): $(OVERVIEW_PAGE_FILE) | $(patsubst %/,%,$(dir $(LINKLIST_FILE)))
	$(FIND_XPATH) -x $(OVERVIEW_PAGE_LINKS_XPATH) -i $< -o $@

# create another Makefile SINGLE_PAGES_DEP_FILE that sets the variables:
# 	- SINGLE_PAGES_STEMS
# 	- SINGLE_PAGES_LINKS
$(SINGLE_PAGES_DEP_FILE): $(LINKLIST_FILE) | $(patsubst %/,%,$(dir $(SINGLE_PAGES_DEP_FILE)))
	$(SINGLE_PAGES_DEP_FILE_CREATOR) < $< > $@

# include SINGLE_PAGES_DEP_FILE
# this auto-generated Makefile also sets the variables
# 	- SINGLE_PAGES_STEMS
# 	- SINGLE_PAGES_LINKS
-include $(SINGLE_PAGES_DEP_FILE)

# function to define a rule to download URL to FILE
# $(call download_single_page_rule,URL,FILE)
define download_single_page_rule
$(2): | $(patsubst %/,%,$(dir $(2)))
	$(call download_url_to_file,$(1),$$@)
endef

# function to loop over two lists
define zip
ifneq ($$(words $(2)),$$(words $(3)))
$$(error zip: lists have different amount of words)
endif
_elements = $$(shell seq $$(words $(2))) # create sequence of indices
# loop over the indices and call $(1) with the current elements of the first and second list
$$(foreach i,$$(_elements),$$(eval $$(call $(1),$$(word $$(i),$(2)),$$(word $$(i),$(3)))))
undefine _elements
endef

SINGLE_PAGES_HTML_FILES = $(addprefix $(HTML_DIR)/,$(addsuffix .$(HTML),$(SINGLE_PAGES_STEMS)))
SINGLE_PAGES_CSV_FILES  = $(addprefix $(DATA_DIR)/,$(addsuffix  .$(CSV),$(SINGLE_PAGES_STEMS)))

# $(info $(call zip,download_single_page_rule,$(SINGLE_PAGES_LINKS),$(SINGLE_PAGES_FILES)))
$(eval $(call zip,download_single_page_rule,$(SINGLE_PAGES_LINKS),$(SINGLE_PAGES_HTML_FILES)))

# extract data from single page
$(DATA_DIR)/%.csv: $(HTML_DIR)/%.$(HTML) | $(DATA_DIR)
	$(SINGLE_PAGE_DATA_EXTRACTOR) -i $< -o $@

# concatenate csv files into one file
$(DATA_FILE_RAW): $(SINGLE_PAGES_CSV_FILES) | $(patsubst %/,%,$(dir $(DATA_FILE_RAW)))
	$(CSV_CONCATENATOR) $^ > $@ 

# sanitize the data
$(DATA_FILE_SANE): $(DATA_FILE_RAW) | $(patsubst %/,%,$(dir $(DATA_FILE)))
	$(DATA_SANITIZER) $< > $@

# create a Makefile that defines the AVAILABLE_YEARS variable
$(AVAILABLE_YEARS_DEP_FILE): $(OVERVIEW_PAGE_FILE) | $(patsubst %/,%,$(dir $(AVAILABLE_YEARS_DEP_FILE)))
	$(FIND_XPATH) -x $(OVERVIEW_PAGE_DATE_XPATH) -i $< \
		| perl -ne 'BEGIN{%y};$$y{$$m[0]}=1 if(@m=m/(\d{4})/);END{print join " ","AVAILABLE_YEARS","=",sort(keys %y),"\n"}' \
		> $@

# include file to get AVAILABLE_YEARS variable
-include $(AVAILABLE_YEARS_DEP_FILE)

# function create_plot(PLOT_NAME,YEAR_START,YEAR_END)
# creates rule to create PLOT_NAME with a corresponding plotscript in
# $(PLOT_SCRIPTS_DIR) with a matching basename
# also, add the plot file to the DEFAULT_TARGET_NAME
define create_plot_rule
ifeq ($(strip $(2)),$(strip $(3))) # if years are equal, only use one
$$(eval PLOT_FILE = $(PLOTS_DIR)/$(1)-$(2).$(PNG))
else
ifeq ($(firstword $(AVAILABLE_YEARS))$(lastword $(AVAILABLE_YEARS)),$(2)$(3))
$$(eval PLOT_FILE = $(PLOTS_DIR)/$(1).$(PNG))
else
$$(eval PLOT_FILE = $(PLOTS_DIR)/$(1)-$(2)-$(3).$(PNG))
endif
endif
$(DEFAULT_TARGET_NAME): $$(PLOT_FILE)
$$(PLOT_FILE): $(DATA_FILE_SANE) | $$(patsubst %/,%,$$(dir $$(PLOT_FILE)))
	$$(shell $(PLOT_SCRIPTS_FIND_CMD) -name '$(basename $(notdir $(1)))*' -print -quit) $$< $(2) $(3) $$@
endef

# create rules for each plot and year
$(foreach NAME,$(PLOT_NAMES),$(foreach YEAR,$(AVAILABLE_YEARS),$(eval $(call create_plot_rule,$(NAME),$(YEAR),$(YEAR)))))
ifneq ($(firstword $(AVAILABLE_YEARS)),$(lastword $(AVAILABLE_YEARS)))
# create rules for whole year range
$(foreach NAME,$(PLOT_NAMES),$(eval $(call create_plot_rule,$(NAME),$(firstword $(AVAILABLE_YEARS)),$(lastword $(AVAILABLE_YEARS)))))
endif

.PHONY:
deploy: all
ifeq ($(strip $(DEPLOY_DIR)),) # no DEPLOY_DIR given
	$(error no DEPLOY_DIR given)
else
	mkdir -p $(DEPLOY_DIR)
	cp -uv $(PLOTS_DIR)/* $(DEPLOY_DIR)
endif

$(TEMP_DIRS): % :
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(OVERVIEW_PAGE_FILE)
	rm -rf $(TEMP_DIRS)
