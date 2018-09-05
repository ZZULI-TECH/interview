# Builder模式

当我们在创建对象的时候，如果对象需要很多的参数，并且有些参数是可选的，有些是必选的，有的可能默认值，这个时候如果我们用构造器传参或者通过set方法进行属性值设置，那么这样就有很大的问题，比如别人在创建这个对象的时候，并不知道需要传哪些参数，哪些参数是必须传值的，而且调用也不方便，所有我们就可以用到Builder模式，这里就是所谓的链式调用。在Effective Java书中， 第2条就是遇到到多个构造器时要考虑用构造器，里面讲的比较详细。

比如我们想这样创建一个对象

```java
new User.Builder("Walker", "Han")
        .age(20)
        .phone("123456789")
        .address("166号")
        .build();
```

此时我们需要在User类中创建一个内部类Builder，该类用来创建User对象，通过上面的代码我们发现，可以连续调用属性的方法进行传参，这就要求每次调用后都要返回当前对象，这样才能连续调用，下面是代码：

```java
/**
 * 链式调用
 * @author mingshan
 *
 */
public class User {
    private final String firstName; // 必传参数 
    private final String lastName; // 必传参数
    private int age; // 可选参数
    private String phone; // 可选参数 
    private String address; // 可选参数

    private User(Builder builder) {
        this.firstName = builder.firstName;
        this.lastName = builder.lastName;
        this.age = builder.age;
        this.phone = builder.phone;
        this.address = builder.address;
    }

    @Override
    public String toString() {
        return "User [firstName=" + firstName + ", lastName=" + lastName + ", age=" + age + ", phone=" + phone
                + ", address=" + address + "]";
    }

    public static class Builder {
        private final String firstName;
        private final String lastName;
        private int age;
        private String phone;
        private String address;

        public Builder(String firstName, String lastName) {
            this.firstName = firstName;
            this.lastName = lastName;
        }

        public Builder age(int age) {
            this.age = age;
            return this;
        }

        public Builder phone(String phone) {
            this.phone = phone;
            return this;
        }

        public Builder address(String address) {
            this.address = address;
            return this;
        }

        public User build() {
            return new User(this);
        }
    }
}

```

然后就可以像上面的方式进行调用了。