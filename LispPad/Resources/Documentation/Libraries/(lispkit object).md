Library `(lispkit object)` implements a simple, delegation-based object system for LispKit. It provides procedural and declarative interfaces for objects and classes. The class system is optional. It mostly provides means to define and manage new object types and construct objects using object constructors.


## Introduction

Similar to other Scheme and Lisp-based object systems, methods of objects are defined in terms of object/class-specific specializations of generic procedures. A generic procedure consists of methods for the various objects/classes it supports. A generic procedure performs a dynamic dispatch on the first parameter (the `self` parameter) to determine the applicable method.

### Generic procedures

Generic procedures can be defined using the `define-generic` form. Here is an example which defines three generic methods, one with only a `self` parameter, and two with three parameters `self`, `x` and `y`. The last generic procedure definition includes a `default` method which is applicable to all objects for which there is no specific method. When a generic procedure without default is applied to an object that does not define its own method implementation, an error gets signaled.

```
(define-generic (point-coordinates self))
(define-generic (set-point-coordinates! self x y))
(define-generic (point-move! self x y)
  (let ((coord (point-coordinate self)))
    (set-point-coordinate! self (+ (car coord) x) (+ (cdr coord) y))))
```

### Objects

An object encapsulates a list of methods each implementing a generic procedure. These methods are regular closures which can share mutable state. Objects do not have an explicit notion of a field or slot as in other Scheme or Lisp-based object systems. Fields/slots need to be implemented via generic procedures and method implementations sharing state. Here is an example explaining this approach:

```
(define (make-point x y)
  (object ()
    ((point-coordinates self) (cons x y))
    ((set-point-coordinates! self nx ny) (set! x nx) (set! y ny))
    ((object->string self) (string-append (object->string x) "/" (object->string y)))))
```

This is a function creating new point objects. The `x` and `y` parameters of the constructor function are used for representing the state of the point object. The created point objects implement three generic procedures: `point-coordinates`, `set-point-coordinates`, and `object->string`. The latter procedure is defined directly by the library and, in general, used for creating a string representation of any object. By implementing the `object->string` method, the behavior gets customized for the object.

The following lines of code illustrate how point objects can be used:

```
(define pt (make-point 25 37))
pt                                              => #object:#<box (...)>
(object->string pt)                             => "25/37"
(point-coordinates pt)                          => (25 . 37)
(set-point-coordinates! pt 5 6)
(object->string pt)                             => "5/6"
(point-coordinates pt)                          => (5 . 6)
```

### Inheritance

The LispKit object system supports inheritance via delegation. The following code shows how colored points can be implemented by delegating all point functionality to the previous implementation and by simply adding only color-related logic.

```
(define-generic (point-color self) #f)
(define (make-colored-point x y color)
  (object ((super (make-point x y)))
    ((point-color self) color)
    ((object->string self)
       (string-append (object->string color) ":" (invoke (super object->string) self)))))
```

The object created in function `make-colored-point` inherits all methods from object `super` which gets set to a new point object. It adds a new method to generic procedure `point-color` and redefines the `object->string` method. The redefinition is implemented in terms of the inherited `object->string` method for points. The form `invoke` can be used to refer to overridden methods in delegatee objects. Thus, `(invoke (super object->string) self)` calls the `object->string` method of the `super` object but with the identity (`self`) of the colored point.

The following interaction illustrates the behavior:

```
(define cpt (make-colored-point 100 50 'red))
(point-color cpt)                               => red
(point-coordinates cpt)                         => (100 . 50)
(set-point-coordinates! cpt 101 51)
(object->string cpt)                            => "red:101/51"
```

Objects can delegate functionality to multiple delegatees. The order in which they are listed determines the methods which are being inherited in case there are conflicts, i.e. multiple delegatees implement a method for the same generic procedure.

### Classes

Classes add syntactic sugar, simplying the creation and management of objects. They play the following role in the object-system of LispKit:

  1. A class defines a constructor for objects represented by this class.
  2. Each class defines an object type, which can be used to distinguish objects created by the same constructor and supporting the same methods.
  3. A class can inherit functionality from several other classes, making it easy to reuse functionality.
  4. Classes are first-class objects supporting a number of class-related procedures.

The following code defines a `point` class with similar functionality as above:

```
(define-class (point x y) ()
  (object ()
    ((point-coordinates self) (cons x y))
    ((set-point-coordinates! self nx ny) (set! x nx) (set! y ny))
    ((object->string self) (string-append (object->string x) "/" (object->string y)))))
```

Instances of this class are created by using the generic procedure `make-instance` which is implemented by all class objects:

```
(define pt2 (make-instance point 82 10))
pt2                                             => #point:#<box (...)>
(object->string pt2)                            => "82/10"
```

Each object created by a class implements a generic procedure `object-class` referring to the class of the object. Since classes are objects themselves we can obtain their name with generic procedure `class-name`:

```
(object-class pt2)                              => #class:#<box (...)>
(class-name (object-class pt2))                 => point
(instance-of? point pt2)                        => #t
(instance-of? point pt)                         => #f
```

Generic procedure `instance-of?` can be used to determine whether an object is a direct or indirect instance of a given class. The last two lines above show that `pt2` is an instance of `point`, but `pt` is not, even though it is functionally equivalent.

The following definition re-implements the colored point example from above using a class:

```
(define-class (colored-point x y color) (point)
  (if (or (< x 0) (< y 0))
      (error "coordinates are negative: ($0; $1)" x y))
  (object ((super (make-instance point x y)))
    ((point-color self) color)
    ((object->string self)
       (string-append (object->string color) ":" (invoke (super object->string) self)))))
```

The following lines illustrate the behavior of `colored-point` objects vs `point` objects:

```
(point-color cpt2)                              => blue
(point-coordinates cpt2)                        => (128 . 256)
(set-point-coordinates! cpt2 64 32)
(object->string cpt2)                           => "blue:64/32"
(instance-of? point cpt2)                       => #t
(instance-of? colored-point cpt2)               => #t
(instance-of? colored-point cpt)                => #f
(class-name (object-class cpt2))                => colored-point
```


## Procedural object interface

**(object? _expr_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

**(make-object)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-object _delegate ..._)**

**(method _obj generic_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

**(object-methods _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

**(add-method! _obj generic method_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

**(delete-method! _obj generic_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

**(make-generic-procedure ...)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  


## Declarative object interface

**(object ...)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  

**(define-generic ...)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  

**(invoke ...)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  



## Procedural class interface

**(class? _expr_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

**root** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[object]</span>  

**(make-class _name superclasses constructor_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

### Instance methods

**(object-class self)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

**(object-equal? self obj)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

**(object->string self)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

### Class methods

**(class-name self)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

**(class-direct-superclasses self)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

**(subclass? self other)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

**(make-instance self . args)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

**(instance-of? self obj)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  


## Declarative class interface

**(define-class ...)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  
