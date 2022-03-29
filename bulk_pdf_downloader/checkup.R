#!/usr/bin/Rscript

library(dplyr)

path_input <- "~/repo/collection/bulk_pdf_downloader/Katalog.csv"
path_output <- "~/repo/collection/bulk_pdf_downloader/output/"

input <- read.csv(path_input)
input <- input["Paparan"]
input <- mutate(input, Paparan = paste0(Paparan, ".pdf"))
input <- as_tibble(arrange(input, Paparan))

output <- list.files(path_output)
output <- data.frame(Paparan = output)
output <- as_tibble(output)

nrow(input) == nrow(output)
nrow(distinct(input)) == nrow(output)

bind_cols(
  rename(input, input = Paparan),
  bind_rows(
    rename(output, output = Paparan),
    tibble(output = rep("dummy", abs(nrow(output)-nrow(input))))
  )
) |> View()

dup <- input[duplicated(input$Paparan),]$Paparan

# duplicated
# [1] "Kesiapan Implementasi Mobil Listrik Sebagai Sarana Angkutan Umum Di Indonesia.pdf"
# [2] "Pembukaan Acara Kepala Badan Penelitian dan Pengembangan Perhubungan.pdf"         
# [3] "Pemetaan Dan Agenda Riset Transportasi Nasional.pdf" 
