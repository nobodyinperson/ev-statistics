#!/usr/bin/make -f

# include make-utils
MAKE_UTILS_PATH = make-utils
MAKE_UTILS_INCLUDES = $(wildcard $(realpath $(MAKE_UTILS_PATH))/*.mk)
include $(MAKE_UTILS_INCLUDES) # include the files

### settings ###
# if ALWAYS_DOWNLOAD_OVERVIEW is true, the overview page is always downloaded
ALWAYS_DOWNLOAD_OVERVIEW = true
OVERVIEW_PAGE_URL = http://www.feuerwehr-aumuehle.de/wopre/alle-einsaetze/alle-einsaetze-2

# extensions
TMP = tmp
DEP = d

# directories
TEMP_DIR = temp
HTML_DIR = html
DEPS_DIR = deps
SCRIPTS_DIR = scripts
TEMP_DIRS = $(TEMP_DIR) $(HTML_DIR) $(DEPS_DIR)

# files
OVERVIEW_PAGE_FILE = $(HTML_DIR)/overview.html
LINKLIST_FILE = $(HTML_DIR)/linklist.txt

# scripts
OVERVIEW_PAGE_LINK_EXTRACTOR = $(SCRIPTS_DIR)/extract-pagelinks-from-overview.py

###############
### targets ###
###############
all: $(LINKLIST_FILE)

# download overview page
ifeq ($(ALWAYS_DOWNLOAD_OVERVIEW),true)
.PHONY: $(OVERVIEW_PAGE_FILE)
endif
$(OVERVIEW_PAGE_FILE): | $(patsubst %/,%,$(dir $(OVERVIEW_PAGE_FILE)))
	$(call download_url_to_file,$(OVERVIEW_PAGE_URL),$@)

# extract linklist from overview page
$(LINKLIST_FILE): $(OVERVIEW_PAGE_FILE) | $(patsubst %/,%,$(dir $(LINKLIST_FILE)))
	$(OVERVIEW_PAGE_LINK_EXTRACTOR) -i $< -o $@


$(TEMP_DIRS): % :
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(OVERVIEW_PAGE_FILE)
	rm -rf $(TEMP_DIRS)
