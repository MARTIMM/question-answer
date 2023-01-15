
class A does Iterable {
  has Array $.a;

#`{{
  method new ( Array :$a ) {
note "self {self}";
    #self = Nil;
    A.bless(:$a);
  }
}}

  method iterator ( A:D: --> Iterator ) {
    my $a = $!a;

    class :: does Iterator {
      has $!count = 0;
      method pull-one ( --> Mu ) {
        return $!count < $a.elems
          ?? $a[$!count++]
          !! IterationEnd;
      }
    }.new;
  }
}

# Must bind to the class object to let 'for' find the .iterator
# the down part is that you can not reassign it with '$a .= new(…)
my A $a := A.new(:a([2,3,6,7]));
.note for $a;

# or using clone
my A $b .= new(:a([1,2,4...64]));
.note for $b.clone;

# now we can reassign easily
$b .= new(:a([3,4,7,8]));
.note for $b.clone;
