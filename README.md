# cellar
Ruby gem to deal with cells of data in rows and columns (CSV, spreadsheets, etc.)

### Example

Sample code:

```ruby
# read CSV
data = DATA.read
rows = data.split("\n").map {|line| line.split(",") }

# show output
info = Cellar.new(rows)
info.each do
  p info[:id, 4, "name", "gym".."age", 6..4, :color, "CaNdY"]
end

__END__
id,name,age,school,gym,color,candy,pet
1,joe,13,Rockville,Gold's,yellow,gum,bird
2,sally,8,Melville,24 Hour Fitness,pink,skittles,pig
3,curly,44,Vegas,Couch,purple,Snicker's,lizard
```

Sample output:

```text
["1", "Gold's", "joe", "Gold's", "Rockville", "13", "gum", "yellow", "Gold's", "yellow", "gum"]
["2", "24 Hour Fitness", "sally", "24 Hour Fitness", "Melville", "8", "skittles", "pink", "24 Hour Fitness", "pink", "skittles"]
["3", "Couch", "curly", "Couch", "Vegas", "44", "Snicker's", "purple", "Couch", "purple", "Snicker's"]
```
