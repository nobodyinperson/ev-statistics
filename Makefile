#!/usr/bin/make -f

# include make-utils
MAKE_UTILS_PATH = make-utils
MAKE_UTILS_INCLUDES = $(wildcard $(realpath $(MAKE_UTILS_PATH))/*.mk)
include $(MAKE_UTILS_INCLUDES) # include the files

### settings ###
OVERVIEW_PAGE_URL = http://www.feuerwehr-aumuehle.de/wopre/alle-einsaetze/alle-einsaetze-2

# extensions
HTML = html
TMP = tmp
LIST = list
MK = mk
CSV = csv

# directories
TEMP_DIR = temp
HTML_DIR = html
DATA_DIR = data
DEPS_DIR = deps
PLOTS_DIR = plots
SCRIPTS_DIR = scripts
TEMP_DIRS = $(TEMP_DIR) $(HTML_DIR) $(DEPS_DIR) $(PLOTS_DIR) $(DATA_DIR)

# files
OVERVIEW_PAGE_FILE = $(HTML_DIR)/overview.$(HTML)
LINKLIST_FILE = $(HTML_DIR)/linklist.$(LIST)
SINGLE_PAGES_DEP_FILE = $(DEPS_DIR)/single-pages.$(MK)
DATA_FILE = $(DATA_DIR)/all-data.$(CSV)

# scripts
OVERVIEW_PAGE_LINK_EXTRACTOR = $(SCRIPTS_DIR)/extract-pagelinks-from-overview.py
SINGLE_PAGE_DATA_EXTRACTOR = $(SCRIPTS_DIR)/extract-data-from-single-page.R
SINGLE_PAGES_DEP_FILE_CREATOR = $(SCRIPTS_DIR)/linklist-to-targets.pl
CSV_CONCATENATOR = $(SCRIPTS_DIR)/concatenate-csv-files.R

###############
### targets ###
###############
all: $(DATA_FILE)

# download overview page
$(OVERVIEW_PAGE_FILE): | $(patsubst %/,%,$(dir $(OVERVIEW_PAGE_FILE)))
	$(call download_url_to_file,$(OVERVIEW_PAGE_URL),$@)

# extract linklist from overview page
$(LINKLIST_FILE): $(OVERVIEW_PAGE_FILE) | $(patsubst %/,%,$(dir $(LINKLIST_FILE)))
	$(OVERVIEW_PAGE_LINK_EXTRACTOR) -i $< -o $@

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
	$(SINGLE_PAGE_DATA_EXTRACTOR) $< $@ # TODO

# concatenate csv files into one file
$(DATA_FILE): $(SINGLE_PAGES_CSV_FILES) | $(patsubst %/,%,$(dir $(DATA_FILE)))
	$(CSV_CONCATENATOR) $^ > $@ # TODO

$(TEMP_DIRS): % :
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(OVERVIEW_PAGE_FILE)
	rm -rf $(TEMP_DIRS)
