# Telehealth Use Among 65+
install.packages("dplyr")
install.packages("survey")
install.packages("gtsummary")
install.packages("gt")
install.packages("broom.helpers")

library(dplyr)
library(survey)
library(gtsummary)
library(gt)

adult24 <- read.csv("data/adult24.csv"
)
adult25 <- read.csv("data/adult25.csv"
)

# ============================================================
# Selecting variables
# ============================================================

df <- bind_rows(
  adult24 %>% mutate(YEAR = 2024),
  adult25 %>% mutate(YEAR = 2025)
) %>%
  select(AGEP_A, HISPALLP_A, YEAR, SEX_A, ORIENT_A, URBRRL23, EDUCP_A, DISAB3_A, COVER65_A, RATCAT_A, VIRAPP12M_A, PSTRAT, PPSU, WTFA_A)

# ============================================================
# Mutating variables
# ============================================================

df <- df %>%
  mutate(
    HISPALLP_A = case_when(
      HISPALLP_A == 1 ~ "Hispanic",
      HISPALLP_A == 2 ~ "Non-Hispanic White only",
      HISPALLP_A == 3 ~ "Non-Hispanic Black/African American only",
      HISPALLP_A == 4 ~ "Non-Hispanic Asian only",
      HISPALLP_A == 5 ~ "Non-Hispanic AIAN only",
      HISPALLP_A == 6 ~ "Non-Hispanic AIAN and any other group",
      HISPALLP_A == 7 ~ "Other single and multiple races",
      HISPALLP_A %in% c(97, 98, 99) ~ NA_character_,
      TRUE ~ NA_character_
    ),
    
    SEX_A = case_when(
      SEX_A == 1 ~ "Male",
      SEX_A == 2 ~ "Female",
      SEX_A %in% c(7, 8, 9) ~ NA_character_,
      TRUE ~ NA_character_
    ),
    
    ORIENT_A = case_when(
      ORIENT_A == 1 ~ "GayLesbian",
      ORIENT_A == 2 ~ "Straight",
      ORIENT_A == 3 ~ "Bisexual",
      ORIENT_A %in% c(4, 5) ~ "Queer or Questioning",
      ORIENT_A %in% c(7, 8) ~ NA_character_,
      TRUE ~ NA_character_
    ),
    
    URBRRL23 = case_when(
      URBRRL23 == 1 ~ "Large central metro",
      URBRRL23 == 2 ~ "Large fringe metro",
      URBRRL23 == 3 ~ "Medium and small metro",
      URBRRL23 == 4 ~ "Nonmetropolitan",
      TRUE ~ NA_character_
    ),
        
    EDUCP_A = case_when(
      YEAR == 2024 & EDUCP_A == 0 ~ "No schooling",
      YEAR %in% c(2024, 2025) & EDUCP_A == 1 ~ "Some schooling",
      YEAR %in% c(2024, 2025) & EDUCP_A %in% c(2, 3, 4) ~ "High School, 12th grade or GED",
      YEAR %in% c(2024, 2025) & EDUCP_A %in% c(5, 6, 7, 8) ~ "Some College Degree",
      YEAR %in% c(2024, 2025) & EDUCP_A == 9 ~ "Master's Degree",
      YEAR %in% c(2024, 2025) & EDUCP_A == 10 ~ "Professional School or Doctoral Degree",
      EDUCP_A %in% c(97, 98, 99) ~ NA_character_, TRUE ~ NA_character_
      ),
        
    DISAB3_A = case_when(
      DISAB3_A == 1 ~ "Yes",
      DISAB3_A == 2 ~ "No",
      DISAB3_A == 9 ~ NA_character_,
      TRUE ~ NA_character_
      ),
        
    COVER65_A = case_when(
      COVER65_A == 1 ~ "Private",
      COVER65_A == 2 ~ "Dual Eligible",
      COVER65_A == 3 ~ "Medicare Advantage",
      COVER65_A == 4 ~ "Medicare only excluding Medicare Advantage",
      COVER65_A == 5 ~ "Other coverage",
      COVER65_A == 6 ~ "Uninsured",
      COVER65_A == 7 ~ NA_character_, TRUE ~ NA_character_
      ),
        
    RATCAT_A = case_when(
      RATCAT_A %in% c(1, 2, 3) ~ "Below Poverty Level",
      RATCAT_A %in% c(4, 5, 6, 7) ~ "Low Income (Near-Poor)",
      RATCAT_A %in% c(8, 9, 10, 11) ~ "Middle Income",
      RATCAT_A %in% c(12, 13, 14) ~ "High Income",
      RATCAT_A == 98 ~ NA_character_, TRUE ~ NA_character_
      ),
    
    VIRAPP12M_A = case_when(
      VIRAPP12M_A == 1 ~ "Yes",
      VIRAPP12M_A == 2 ~ "No",
      VIRAPP12M_A %in% c(97, 98, 99) ~ NA_character_,
      TRUE ~ NA_character_
    ),
    
    across(
      c(
        HISPALLP_A, SEX_A, ORIENT_A, URBRRL23,
        EDUCP_A, DISAB3_A, COVER65_A,
        RATCAT_A, VIRAPP12M_A
      ),
    as.factor
  )
)

# ============================================================
# Adjusting weights and defining strata
# ============================================================
df <- df %>%
  mutate(
    WTFA_pooled = WTFA_A / 2   #since there are 2 years we are account for
  )
options(survey.lonely.psu = "adjust")

nhis_design <- svydesign(
  ids = ~PPSU,
  strata = ~PSTRAT,
  weights = ~WTFA_pooled,
  data = df,
  nest = TRUE
)

# ============================================================
# Subsetting
# ============================================================
nhis_65plus <- subset(
  nhis_design,
  AGEP_A >= 65
)

# ============================================================
# Table 1
# ============================================================

table1 <- nhis_65plus %>%
  tbl_svysummary(
    by = VIRAPP12M_A,
    include = c(
      AGEP_A, HISPALLP_A, YEAR,
      SEX_A, ORIENT_A,  URBRRL23, EDUCP_A,
      DISAB3_A, COVER65_A, RATCAT_A
    ),
    statistic = list(
      all_categorical() ~ "{n} ({p}%)",
      all_continuous() ~ "{mean} ({sd})"
    ),
    missing = "ifany"
  ) %>%
  add_p() %>%
  bold_labels()

table1 %>%
  as_gt() %>%
  gt::gtsave("outputs/Table1_NHIS_by_Outcome.html")


# ============================================================
# Regression Modelling
# ============================================================

nhis_65plus <- update(
  nhis_65plus,
  
  # Outcome: Accessed telehealth
  VIRAPP12M_A = relevel(
    factor(VIRAPP12M_A),
    ref = "No"
  ),
  
  # Race/Ethnicity
  HISPALLP_A = relevel(
    factor(HISPALLP_A),
    ref = "Non-Hispanic White only"
  ),
  
  # Sex
  SEX_A = relevel(
    factor(SEX_A),
    ref = "Male"
  ),
  
  # Sexual Orientation
  ORIENT_A = relevel(
    factor(ORIENT_A),
    ref = "Straight"
  ),
  
  # Urban/Rural
  URBRRL23 = relevel(
    factor(URBRRL23),
    ref = "Large central metro"
  ),
  
  # Education
  EDUCP_A = relevel(
    factor(EDUCP_A),
    ref = "Some schooling"
  ),
  
  # Disability
  DISAB3_A = relevel(
    factor(DISAB3_A),
    ref = "No"
  ),
  
  # Insurance
  COVER65_A = relevel(
    factor(COVER65_A),
    ref = "Private"
  ),
  
  # Income
  RATCAT_A = relevel(
    factor(RATCAT_A),
    ref = "High Income"
  ),
  
  # Survey year: 2024 is reference
  YEAR = relevel(
    factor(YEAR),
    ref = "2024"
  )
)



# ============================================================
# MODEL 1 — UNADJUSTED REGRESSIONS
# ============================================================


# 1. Age
model_age <- svyglm(
  VIRAPP12M_A ~ AGEP_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_age)

# 2. Race/Ethnicity
model_race <- svyglm(
  VIRAPP12M_A ~ HISPALLP_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_race)

# 3. Survey Year
model_year <- svyglm(
  VIRAPP12M_A ~ YEAR,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_year)

# 4. Sex
model_sex <- svyglm(
  VIRAPP12M_A ~ SEX_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_sex)


# 5. Sexual Orientation
model_orientation <- svyglm(
  VIRAPP12M_A ~ ORIENT_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_orientation)

# 6. Urban/Rural Residence
model_urban <- svyglm(
  VIRAPP12M_A ~ URBRRL23,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_urban)

# 7. Education
model_education <- svyglm(
  VIRAPP12M_A ~ EDUCP_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_education)

# 8. Disability
model_disability <- svyglm(
  VIRAPP12M_A ~ DISAB3_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_disability)

# 9. Insurance Coverage
model_insurance <- svyglm(
  VIRAPP12M_A ~ COVER65_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_insurance)

# 10. Income
model_income <- svyglm(
  VIRAPP12M_A ~ RATCAT_A,
  design = nhis_65plus,
  family = quasibinomial()
)
summary(model_income)


# ============================================================
# MODEL 2 — MULTIVARIABLE REGRESSION
# ============================================================

model2 <- svyglm(
  VIRAPP12M_A ~
    AGEP_A +
    HISPALLP_A +
    YEAR +
    SEX_A +
    ORIENT_A +
    URBRRL23 +
    EDUCP_A +
    DISAB3_A +
    COVER65_A +
    RATCAT_A,
  
  design = nhis_65plus,
  family = quasibinomial()
)

summary(model2)


# ============================================================
# TABLE 2
# ============================================================
exposures <- c(
  "AGEP_A",
  "HISPALLP_A",
  "YEAR",
  "SEX_A",
  "ORIENT_A",
  "URBRRL23",
  "EDUCP_A",
  "DISAB3_A",
  "COVER65_A",
  "RATCAT_A"
)

table2_unadjusted <- tbl_uvregression(
  nhis_65plus,
  method = svyglm,
  y = VIRAPP12M_A,
  include = all_of(exposures),
  method.args = list(
    family = quasibinomial()
  ),
  exponentiate = TRUE,
  hide_n = TRUE
)

table2_adjusted <- tbl_regression(
  model2,
  exponentiate = TRUE
)

table2 <- tbl_merge(
  tbls = list(
    table2_unadjusted,
    table2_adjusted
  ),
  tab_spanner = c(
    "**Unadjusted OR (95% CI)**",
    "**Adjusted OR (95% CI)**"
  )
) %>%
  bold_labels()

table2 %>%
  as_gt() %>%
  gt::gtsave("outputs/Table2_NHIS_Regression.html")
