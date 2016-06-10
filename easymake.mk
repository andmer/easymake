# author       : roxma
# version      : 7
# Descriptions : A generic makefiles under linux, to help you build 
#                your c/c++ programs easily without writing a long 
#                long tedious makefile.
# github       : https://github.com/roxma/easymake

# Execute "make show" for debug information.

# basic settings

# do not use ./bin
BUILD_ROOT?=bin


# CFLAGS=
# CPPFLAGS=
# LDFLAGS=

# VPATH=

CPPEXT?=cpp
CEXT?=c

CC?=gcc
CXX?=g++
AR?=ar

# TARGET=

################################################################

##
# A function to Check whether a string is begin with a non-empty 
# substring. If not, the result is empty string. Otherwise the result 
# is the substring.
# @param 1 substring to begin with
# @param 2 source string
BeginWith=$(if $(2),$(if $(patsubst $(1)%,,$(2)),,$(1)),)

##
# A function to read settings from a text file. Any line begin with
# a '#' character will be treated as comment and ommitted. Others
# will be in the result.
# $(call ReadSettings, $(file_name))
ReadSettings=$(shell if [ -f $(1) ]; then grep -v "^\#" $(1); fi;)

##
# A function to read the n-th line of a text file.
# $(call ReadLine, fine_name, line_num)
ReadLine=$(shell if [ -f $(1) ]; then sed -n $(2)p $(1); fi;)

## 
# @param 1 The word to find.
# @param 2 list of words
WordExist=$(strip $(foreach word,$(2),$(if $(patsubst $(strip $(1)),,$(strip $(word))),,$(1))))

##
# @param 1 A sub-word.
# @param 2 list of words.
# @param 3 error to show if no matched. If empty, this parameter has no
#   effect.
SelectFirstMatch=$(if $(word 1,$(foreach word,$(2),$(if $(findstring $(1),$(word)),$(word),) )),$(word 1,$(foreach word,$(2),$(if $(findstring $(1),$(word)),$(word),) )),$(if $(3),$(error $(3)),))

##
# Check if the file exists
# # @param 1 The file name
# # @note A name with $(VPATH) as base will fail here
FileExist=$(if $(wildcard $(1)),yes,)

##
# Search the path of the files, if a file name is based on $(VPATH), Then the
# corresopnding result of that element will be $(VPATH)/$(1)
# @param 1 A list of file name
SearchFilePath=$(foreach file,$(1),$(if $(call FileExist,$(file)),$(file),$(foreach vpathDir,$(VPATH),$(if $(call FileExist,$(vpathDir)/$(file)),$(vpathDir)/$(file)))))

##
# @param 1 Entry name
GetEntryPath4Timestamp=$(if $(call SearchFilePath,$(1)),$(call SearchFilePath,$(1)),$(shell if [ ! -f $(BUILD_ROOT)/easy_make_entry_timestamp_$(1) ]; then  touch $(BUILD_ROOT)/easy_make_entry_timestamp_$(1); fi)$(BUILD_ROOT)/easy_make_entry_timestamp_$(1))

##
# If the user specifies $(ENTRY), and the $(ENTRY) is not a file, update its 
# timestamp, so that this entry will be picked next time.
ifneq ($(ENTRY),)
ifeq ($(strip $(call SearchFilePath,$(ENTRY))),)
    $(shell mkdir -p $(dir $(BUILD_ROOT)/easy_make_entry_timestamp_$(ENTRY)))
    $(shell touch $(BUILD_ROOT)/easy_make_entry_timestamp_$(ENTRY))
endif
endif

##
# Get the file with the newest timestamp
# @param 1 A list of files
# @return The index of files in the list
GetNewestFileIndex=$(shell newestIndex=1 && index=1 && newest=$(call GetEntryPath4Timestamp,$(word 1,$(1))) && for file in $(foreach file,$(1),$(call GetEntryPath4Timestamp,$(file)) ) ; do if [ $$file -nt $$newest ] ; then newest=$$file; newestIndex=$$index; fi; let index+=1; done && echo $$newestIndex)

##
# A function to decide the actual entry file.
# @param 1 the user-specified entry, could be an empty string
# @param 2 entry_list
# @param 3 error message if this function failed. If the entry is neither
# empty nor in the entry_list.
GetEntry=$(if $(1),$(if $(call WordExist,$(1),$(2)),$(1),$(call SelectFirstMatch,$(1),$(2),$(3))),$(word $(call GetNewestFileIndex,$(2)),$(2)))

##
# Filter-out the sources that will not finally be linked into the target.
# @param 1 SOURCES 
# @param 2 ENTRY 
# @param 3 ENTRY_LIST
FilterSourcesToLink=$(filter-out $(filter-out $(2),$(3)), $(1))

##
# @param 1 sources
# @param 2 build_root
# @param 3 source file extension
GetCorrendingObjects=$(foreach _src,$(1),$(2)/$(_src:.$(3)=.o))

##
# Recursive wildcard
RWildcard=$(foreach d,$(wildcard $1*),$(call RWildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

##
# @param 1 file name
# @param 2 key
ConfReadValue=$(shell cat $1 | awk  '{if ($$1=="$2") print $$2; }')

##
# @param 1 file name
# @param 2 key
# @param 3 value
CmdConfWriteValue= touch $1 ; fileContents="`cat $1`" ; echo "$$fileContents" |  awk '{if ((NF==2)&&($$1!="$2")) print $$1,$$2 ; } END{print "$2","$3" ;}' > $1


################################################################

ifneq (,$(call BeginWith,./,$(BUILD_ROOT)))
    # "./" in BUILD_ROOT may cause entry detecting problem.
    $(error Please do not use prefix "./" in variable BUILD_ROOT=$(BUILD_ROOT))
endif

# if CPPSOURCES are not specified, automatically scan all .$(CPPEXT) files in the 
# current directories.
ifeq ($(strip $(CPPSOURCES)),)
    CPPSOURCES:=$(call RWildcard,,*.$(CPPEXT)) $(foreach dir,$(VPATH),$(foreach src,$(call RWildcard,$(dir),*.$(CPPEXT)),$(src:$(dir)/%=%)))
    CPPSOURCES:=$(strip $(CPPSOURCES))
endif
ifneq (,$(findstring ..,$(CPPSOURCES)))
    $(error ".." should not appear in the cpp source list: $(CPPSOURCES))
endif
# remove "./" in file path, which may cause pattern rules problems.
CPPSOURCES:=$(subst ./,,$(CPPSOURCES))

# if CSOURCES are not specified, automatically scan all .$(CEXT) files in the 
# current directories.
ifeq ($(strip $(CSOURCES)),)
    CSOURCES:=$(call RWildcard,,*.$(CEXT)) $(foreach dir,$(VPATH),$(foreach src,$(call RWildcard,$(dir),*.$(CEXT)),$(src:$(dir)/%=%)))
    CSOURCES:=$(strip $(CSOURCES))
endif
ifneq (,$(findstring ..,$(CSOURCES)))
    $(error ".." should not appear in the c source list: $(CSOURCES))
endif
# remove "./" in file path, which may cause pattern rules problems.
CSOURCES:=$(subst ./,,$(CSOURCES))


ifneq ($(strip $(CPPSOURCES)),)
    easy_make_linker:=$(CXX)
endif
easy_make_linker?=$(CC)

easy_make_all_cppobjects:=$(call GetCorrendingObjects,$(CPPSOURCES),$(BUILD_ROOT),$(CPPEXT))
easy_make_all_cobjects:=$(call GetCorrendingObjects,$(CSOURCES),$(BUILD_ROOT),$(CEXT))


# A file that contains a list of entries detected by easy_make.
easy_make_f_detected_entries:=$(BUILD_ROOT)/easy_make_detected_entries

easy_make_f_target_last_entry:=$(BUILD_ROOT)/easy_make_target_last_entry


# the first default goal
$(BUILD_ROOT)/target:


##
# show variables in this make file
#
.PHONY: show
show:
	@echo "---------------------"
	@echo "basic settings:"
	@echo "BUILD_ROOT          : $(BUILD_ROOT)"
	@echo "TARGET              : $(TARGET)"
	@echo "VPATH               : $(VPATH)"
	@echo "CPPEXT              : $(CPPEXT)"
	@echo "CEXT                : $(CEXT)"
	@echo "CC                 : $(CC)"
	@echo "CXX                 : $(CXX)"
	@echo "LINKER              : $(LINKER)"
	@echo "---------------------"
	@echo "user settings:"
	@echo "ENTRY_LIST          : $(ENTRY_LIST)"
	@echo "ENTRY               : $(ENTRY)"
	@echo "LINK_FLAGS          : $(LINK_FLAGS)"
	@echo "AR_FLAGS            : $(AR_FLAGS)"
	@echo "CPPSOURCES          : $(CPPSOURCES)"
	@echo "CSOURCES            : $(CSOURCES)"


##
# clean all .o .d .a .so files recursively in the BUILD_ROOT
#
clean:
clean: easy_make_clean
.PHONY: easy_make_clean
easy_make_clean:
	rm -f $$(find $(BUILD_ROOT ) -name "*.o"   )
	rm -f $$(find $(BUILD_ROOT ) -name "*.d"   )
	rm -f $$(find $(BUILD_ROOT ) -name "*.a"   )
	rm -f $$(find $(BUILD_ROOT ) -name "*.so"  )
	rm -f $$(find $(BUILD_ROOT ) -name "*.out" )

##
# 
#
easy_make_build_goals:=$(filter $(BUILD_ROOT)/%,$(MAKECMDGOALS))
ifeq ($(MAKECMDGOALS),)
easy_make_build_goals:=$(filter $(BUILD_ROOT)/%,$(.DEFAULT_GOAL))
endif

easy_make_build_goals:=$(filter-out $(BUILD_ROOT)/%.o $(BUILD_ROOT)/%.d $(BUILD_ROOT)/easy_make%,$(easy_make_build_goals))
ifneq ($(easy_make_build_goals),)


##
# Pattern rule Descriptions:
# 1. Prepare the directories, where the object file is gonna be created.
# 2. Generate the .d dependency file, which specify what files this object 
#    files depends on. This is useful in the next make.
# 3. Compile the source code to object file.
# 4. Prepare $(easy_make_f_detected_entries), which is not empty.
# 5. 
# 6. Delete the name of the source file this target corresponds to, if it is 
#    listed in file $(easy_make_f_detected_entries). Note that the grep command 
#    returns non-zero code if its output is empty, thus we have to make sure 
#    that the file $(easy_make_f_detected_entries) is not empty.
# 7. If there is a main function defined in this object, add this file into the 
#    list defined in the file $(easy_make_f_detected_entries).
#
$(BUILD_ROOT)/%.o: %.$(CPPEXT)
	@mkdir -p $(dir $@)
	@$(CXX) -MM -MP -MF"$(@:.o=.d)" -MT"$@" $(CPPFLAGS) $(word 1,$^) 
	$(CXX) -c -o $@ $(word 1,$^) $(CPPFLAGS)
	@if [ ! -f $(easy_make_f_detected_entries) ]; then echo " " > $(easy_make_f_detected_entries); fi;
	@grep -v "^$(patsubst $(BUILD_ROOT)/%.o,%.$(CPPEXT),$@)$$" $(easy_make_f_detected_entries) > $(BUILD_ROOT)/easy_make_entries_tmp.d 
	@cp $(BUILD_ROOT)/easy_make_entries_tmp.d $(easy_make_f_detected_entries)
	@if [ $$(nm -g -C --format="posix" $@ | grep -c "^main T") -eq 1 ]; then echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CPPEXT),$@)" >> $(easy_make_f_detected_entries) && echo "    entry detected"; fi;

$(BUILD_ROOT)/%.o: %.$(CEXT)
	@mkdir -p $(dir $@)
	@$(CC) -MM -MP -MF"$(@:.o=.d)" -MT"$@" $(CFLAGS) $(word 1,$^) 
	$(CC) -c -o $@ $(word 1,$^) $(CFLAGS)
	@if [ ! -f $(easy_make_f_detected_entries) ]; then echo " " > $(easy_make_f_detected_entries); fi;
	@grep -v "^$(patsubst $(BUILD_ROOT)/%.o,%.$(CEXT),$@)$$" $(easy_make_f_detected_entries) > $(BUILD_ROOT)/easy_make_entries_tmp.d 
	@cp $(BUILD_ROOT)/easy_make_entries_tmp.d $(easy_make_f_detected_entries)
	@if [ $$(nm -g -C --format="posix" $@ | grep -c "^main T") -eq 1 ]; then echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CEXT),$@)" >> $(easy_make_f_detected_entries) && echo "    entry detected"; fi;


##
# include all generated dependency files
#
ifneq ($(strip $(easy_make_all_cppobjects)),)
    sinclude $(easy_make_all_cppobjects:.o=.d)
endif
ifneq ($(strip $(easy_make_all_cobjects)),)
    sinclude $(easy_make_all_cobjects:.o=.d)
endif


##
# If ENTRY is explicitly specified from command line, then check if 
# this ENTRY is different from last last the ENTRY last built with.
# If different, make the goals phony targets.
# @note Use the function "filter" instead of "findstring" here, because
#   $(findstring a,abc) will get an "a". we need to use "filter" to 
#   compare the equality of a and abc.
#
ifneq ($(ENTRY),)
.PHONY: $(foreach goal,$(easy_make_build_goals),$(if $(filter $(ENTRY),$(call ConfReadValue,$(easy_make_f_target_last_entry),$(goal))),,$(goal)))
endif


##
# easy_make_cppsources: cpp files with unused entries filtered-out.
#
easy_make_entry_list = $(ENTRY_LIST) $(call ReadSettings,$(easy_make_f_detected_entries))
easy_make_entry      = $(if $(filter $(ENTRY),NONE)$(filter $(ENTRY),none),,$(call GetEntry,$(ENTRY),$(easy_make_entry_list),"ENTRY=$(ENTRY) is neither defined in the entry_list nor detected by easy_make."))
easy_make_cppsources = $(call FilterSourcesToLink , $(CPPSOURCES) , $(easy_make_entry) , $(easy_make_entry_list))
easy_make_csources   = $(call FilterSourcesToLink , $(CSOURCES)   , $(easy_make_entry) , $(easy_make_entry_list))
easy_make_objects    = $(call GetCorrendingObjects,$(easy_make_cppsources),$(BUILD_ROOT),$(CPPEXT)) $(call GetCorrendingObjects,$(easy_make_csources),$(BUILD_ROOT),$(CEXT))

easy_make_build_goals_tmp := $(easy_make_build_goals)
easy_make_build_goals_ar   := $(filter %.a,$(easy_make_build_goals_tmp))
easy_make_build_goals_tmp      := $(filter-out %.a,$(easy_make_build_goals_tmp))
easy_make_build_goals_link := $(easy_make_build_goals_tmp)

##
# note: When different $(TARGET) or different $(ENTRY) is set by user at command line, this build would be PHONY
#
$(easy_make_build_goals_link): $(easy_make_all_cppobjects) $(easy_make_all_cobjects)
	@echo
	$(easy_make_linker) -o $@ $(easy_make_objects) $(LDFLAGS)
	@echo "ENTRY  :      $(easy_make_entry)"
	@echo "TARGET :      $@"
	@$(call CmdConfWriteValue,$(easy_make_f_target_last_entry),$@,$(easy_make_entry))

$(easy_make_build_goals_ar): $(easy_make_all_cppobjects) $(easy_make_all_cobjects)
	@echo
	$(AR) cr $@ $(easy_make_objects) $(AR_FLAGS)
	@echo "ENTRY  :      $(easy_make_entry)"
	@echo "TARGET :      $@"
	@$(call CmdConfWriteValue,$(easy_make_f_target_last_entry),$@,$(easy_make_entry))


endif # ifneq ($(easy_make_build_goals),)

