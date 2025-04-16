library(tidyverse)

parse_file <- function(path) {
    read_lines(path) %>% 
        enframe("cluster", "pid") %>% 
        mutate_at("pid", str_split, "\t") %>% 
        unnest(pid) %>%  
        transmute(
            pid,
            cluster = str_c("C", cluster) %>% 
                fct_lump_min(100, other = "rest") %>% 
                fct_infreq()
        ) %>% 
        mutate_at("cluster", fct_relevel, "rest", after = Inf)
}

clst <- snakemake@input[["clst"]] %>% 
    enframe("id", "path") %>% 
    extract(
        path, remove = FALSE, convert = TRUE,
        into = c("co", "cnn", "pi", "ip"),
        regex = "([^-]+)-([^-]+)-([^-]+)-([^-]+).membs"
    ) %>% 
    mutate(data = map(path, parse_file)) %>% 
    unnest(data) %>% 
    select(pid, ip, cluster) %>%
    mutate(ip = format(num(ip, digits=1))) %>%
    arrange(as.numeric(pid), ip)

write_tsv(clst, snakemake@output[["all"]])
