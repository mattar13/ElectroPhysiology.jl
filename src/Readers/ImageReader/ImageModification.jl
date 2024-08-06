function adjustBC!(exp; 
     min_val_y = 0.0, max_val_y = 1.0, 
     min_val_x = :auto, max_val_x = :auto,
     contrast = :auto, brightness = :auto,
     n_vals = 10
)
     for (i, ch) in enumerate(eachchannel(exp))
          if min_val_x == :auto
               min_val_x = minimum(ch)
          elseif min_val_x == :std
               mean_val = mean(ch, dims = (1,2))[1,1,1]
               std_val = std(ch, dims = (1,2))[1,1,1]
               min_val_x = mean_val - std_val
          elseif min_val_x == :ci
               mean_val = mean(ch, dims = (1,2))[1,1,1]
               std_val = std(ch, dims = (1,2))[1,1,1]
               min_val_x = mean_val - std_val/sqrt(length(ch))
          end

          if max_val_x == :auto
               max_val_x = maximum(ch)
          elseif max_val_x == :std
               mean_val = mean(ch, dims = (1,2))[1,1,1]
               std_val = std(ch, dims = (1,2))[1,1,1]

               max_val_x = mean_val + std_val
          elseif max_val_x == :ci
               mean_val = mean(ch, dims = (1,2))[1,1,1]
               std_val = std(ch, dims = (1,2))[1,1,1]
               max_val_x = mean_val + std_val/sqrt(length(ch))
          end

          if contrast == :auto
               input_range = LinRange(min_val_x, max_val_x, n_vals)
               output_range = LinRange(min_val_y, max_val_y, n_vals)
               lin_fit = curve_fit(LinearFit, input_range, output_range)
          else
               lin_fit(x) = contrast*x + brightness
          end
          exp.data_array[:,:,i] .= lin_fit.(ch.data_array)
     end
     return exp
end