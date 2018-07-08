# 二叉搜索树

二叉查找树（Binary Search Tree），（又：二叉搜索树，二叉排序树），它具有以下特点：

1. 若任意节点的左子树不空，则左子树上所有结点的值均小于它的根结点的值；
2. 若任意节点的右子树不空，则右子树上所有结点的值均大于它的根结点的值；
3. 任意节点的左、右子树也分别为二叉查找树；
4. 没有键值相等的节点。

下面是一个二叉查找树的示例：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/BinarySearchTree.png?raw=true)

### 基本操作
既然二叉查找树也属于二叉树，那么二叉树的基本操作二叉查找树也需要实现，下面是基本操作

- 查找结点
- 插入结点
- 删除结点

我们先写个接口来定义要实现这些操作，代码如下：

```java
/**
 * 树的接口
 * @author mingshan
 *
 */
public interface Tree<E> {

    /**
     * 插入操作
     * @param value
     * @return 插入成功 ，返回 {@true}，否则返回{@false}
     */
    boolean add(E value);

    /**
     * 移除
     * @param value
     * @return 移除的元素
     */
    E remove(E value);

    /**
     * 清空二叉树
     */
    void clear();

    /**
     * 判断二叉树中是否有此元素
     * @param value
     * @return 如果包含，返回{@true}，否则返回{@false}
     */
    boolean contains(E value);

    /**
     * 获取二叉树中结点的数量
     * @return 二叉树中结点的数量
     */
    int size();
}

```

下面来依次实现。

### 初始化

先在类中定义二叉查找树的根结点和结点数量的成员变量。然后定义一个静态内部类Node来表示结点，代码如下：

```java
// 根结点
private Node<E> root;
// 二叉树结点数量
private int size;

private static class Node<E extends Comparable<E>> {
    E item;
    Node<E> parent;
    Node<E> left;
    Node<E> right;

    public Node (Node<E> parent, E item) {
        this.parent = parent;
        this.item = item;
    }

    @Override
    public String toString() {
        return "item=" + item + " parent=" + ((parent != null) ? parent.item : "NULL") + " left="
                + ((left != null) ? left.item : "NULL") + " right=" + ((right != null) ? right.item : "NULL");
    }
}
```

### 查找结点

这里采用先序遍历二叉查找树，先访问根结点，然后遍历左子树，最后遍历右子树。这里的泛型参数需要继承Comparable，然后我们就可以利用其compareTo方法来比较结点的值然后进行搜索即可。
代码如下：

```java
@Override
public boolean contains(E value) {
    // 先序遍历二叉树
    Node<E> node = root;
    if (root.item.compareTo(value) == 0) {
        return true;
    }

    while (node != null) {
        // 如果当前值比父节点的值小
        if (node.item.compareTo(value) > 0) {
            // 此时应该从父节点的左子树进行搜索
            if (node.left != null
                    && (node.left.item.compareTo(value) == 0)) {
                return true;
            }
            node = node.left;
        } else {
            // 如果当前结点的值比父结点的值大，说明应该从父节点的右子树搜索
            // 并且新结点作为叶子结点，其父节点的右子结点应为null
            if (node.right != null 
                    && (node.right.item.compareTo(value) == 0)) {
                return true;
            }
            node = node.right;
        }
    }
    return false;
}
```

### 插入结点

根据二叉搜索树的特征，若它的左子树不空，则左子树上所有结点的值均小于它的根结点的值； 若它的右子树不空，则右子树上所有结点的值均大于它的根结点的值。而且新插入的结点必为叶子结点，所以只需遍历到当前符合上面要求的结点，然后将其为空的左子结点或者右子结点指向当前的新节点，最后将新结点的父结点指向当前结点。代码如下：


```java
@Override
public boolean add(E value) {
    Node<E> node = addNode(value);
    return (node != null);
}

private Node<E> addNode(E value) {
    // 生成新结点
    Node<E> newNode = new Node<E>(null, value);
    // 如果根结点不存在
    if (root == null) {
        root = newNode;
        size++;
        return newNode;
    }

    Node<E> node = root;
    // 按照先序进行遍历二叉树
    while (node != null) {
        // 如过新结点的值比父节点的值小
        if (node.item.compareTo(newNode.item) > 0) {
            // 此时应该从父节点的左子树进行搜索
            // 并且新结点作为叶子结点，其父节点的左子结点应为null
            if (node.left == null) {
                node.left = newNode;
                newNode.parent = node;
                size++;
                return newNode;
            }
            node = node.left;
        } else {
            // 如果当前结点的值比父结点的值大，说明应该从父节点的右子树搜索
            // 并且新结点作为叶子结点，其父节点的右子结点应为null
            if (node.right == null) {
                node.right = newNode;
                newNode.parent = node;
                size++;
                return newNode;
            }
            node = node.right;
        }
    }

    return newNode;
}
```

### 删除结点

删除结点是操作中最为复杂的，分下面几种情况考虑：

1. 要删除的结点为叶子结点，没有左右子节点
2. 要删除的结点只有左子结点(树)或者右子结点(树)
3. 要删除的结点左右结点(树)都有

下面这幅图代表这几种操作示例：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/BinarySearchTree_remove.png?raw=true)

其中第一幅图代表要删除的结点只有右子结点(树)，只需将该结点的父结点指向该结点的右子结点，但要判断当前结点是其父结点的子左结点还是右子结点，然后对应指向当前结点的子结点即可；图二代表要删除的结点只有左子结点(树)，原理是一样的；图三是代表要删除的结点左右结点(树)都有，此时需要找出其右子树中的最小值代替该节点上的值，然后删除其右子树上的最小值。代码如下：

```java
@Override
public E remove(E value) {
    Node<E> node = this.removeValue(value);
    return (node != null ? node.item : null);
}

private Node<E> removeValue(E value) {
    Node<E> curr = this.getNode(value);
    if (curr != null) {
        curr = removeNode(curr);
    }

    return curr;
}

/**
 * 删除结点，分下面几种情况考虑
 * <ul>
 *   <li>要删除的结点为叶子结点，没有左右子节点</li>
 *   <li>要删除的结点只有左子结点(树)或者右子结点(树)</li>
 *   <li>要删除的结点左右结点(树)都有</li>
 * </ul>
 * @param nodeToRemoved
 * @return 删除的结点
 */
private Node<E> removeNode(Node<E> nodeToRemoved) {
    // 判断当前节点是否为叶子结点（叶子结点的特点是没有子结点）
    // 直接删除叶子结点
    if (nodeToRemoved.left == null && nodeToRemoved.right == null) {
        // 判断该二叉树是否只有根结点一个结点
        if (nodeToRemoved == root) {
            root = null;
            return root;
        }
        // 如果二叉树不是只有根结点一个结点，那么当前要删除的结点一定有父结点
        Node<E> targetParent = nodeToRemoved.parent;
        // 判断当前结点是其父结点的左子结点还是右子结点
        if (targetParent.left.item.compareTo(nodeToRemoved.item) == 0) {
            // 如果当前结点是其父结点的左子结点
            targetParent.left = null;
        } else if (targetParent.right.item.compareTo(nodeToRemoved.item) == 0){
            // 如果当前结点是其父结点的右子结点
            targetParent.right = null;
        } else {
            // 此时二叉树有问题
            return null;
        }
    } else if (nodeToRemoved.left != null && nodeToRemoved.right != null) {
        // 要删除的结点左右结点(树)都有
        // 此时结点的左右子结点(树)都有，用其右子树中的最小值代替该节点上的值,删除其右子树上的最小值
        // 所以此时需要先找出其右子树的最小值
        Node<E> minNode = findMinNode(nodeToRemoved);
        // 将当前要删除结点的值替换为其子树的最小节点
        nodeToRemoved.item = minNode.item;
        // 删除找到的最小节点
        removeNode(minNode);
    } else {
        // 要删除的结点只有左子结点(树)或者右子结点(树)
        // 此时需要将该结点的子结点(树)指向该结点(树)的父结点
        Node<E> targetLeft = nodeToRemoved.left;
        Node<E> targetRight = nodeToRemoved.right;
        Node<E> targetParent = nodeToRemoved.parent;
        // 判断当前要删除的结点是其父结点的左结点还是右结点
        if (targetParent.left.item.compareTo(nodeToRemoved.item) == 0) {
            // 左
            if (targetLeft != null) {
                targetParent.left = targetLeft;
                targetLeft.parent = targetParent;
                targetLeft = null;
            }
            if (targetRight != null) {
                targetParent.left = targetRight;
                targetRight.parent = targetParent;
                targetRight = null;
            }
        } else if (targetParent.right.item.compareTo(nodeToRemoved.item) == 0) {
            // 右
            if (targetLeft != null) {
                targetParent.right = targetLeft;
                targetLeft.parent = targetParent;
                targetLeft = null;
            }
            if (targetRight != null) {
                targetParent.right = targetRight;
                targetRight.parent = targetParent;
                targetRight = null;
            }
        }
    }

    size--;
    return nodeToRemoved;
}
```

我们需要通过传入的值来获取二叉树的结点，此时调用函数**getNode**，代码如下：


```java
/**
 * 通过传入的值来搜索结点
 * @param value 传入的值
 * @return 结点
 */
private Node<E> getNode(E value) {
    Node<E> node = root;
    while (node != null && node.item != null) {
        if (node.item.compareTo(value) > 0) {
            node = node.left;
        } else if (node.item.compareTo(value) < 0) {
            node = node.right;
        } else {
            return node;
        }
    }

    return null;
}
```

在要删除的结点左右结点(树)都有的情况下，我们需要查找其右子树中的最小值，此时我们考虑到如果为最小结点，那么该结点必然没有左子树(结点)，所以可以选择递归进行遍历，代码如下：

```java
/**
 * 找到给定结点的子树的最小结点(值)
 * 此时应该考虑到如果为最小结点，那么该结点必然没有左子树(结点)，所以可以选择递归进行遍历
 * @param nodeToRemoved
 * @return 给定结点的子树的最小结点(值)
 */
private Node<E> findMinNode(Node<E> nodeToRemoved) {
    if (nodeToRemoved == null) {
        return null;
    }
    if (nodeToRemoved.left == null) {
        return nodeToRemoved;
    }

    return findMinNode(nodeToRemoved.left);
}
```

### 打印

我们需要将二叉树打印到控制台上，便于查看二叉树的结构，效果如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/BinarySearchTree_print.png?raw=true)

打印代码如下：

```java
@Override
public String toString() {
    return TreePrinter.getString(this);
}

protected static class TreePrinter {

    public static <T extends Comparable<T>> String getString(BinarySearchTree<T> tree) {
        if (tree.root == null)
            return "Tree has no nodes.";
        return getString(tree.root, "", true);
    }

    private static <E extends Comparable<E>> String getString(Node<E> node, String prefix, boolean isTail) {
        StringBuilder builder = new StringBuilder();

        if (node.parent != null) {
            String siteme = "left";
            if (node.equals(node.parent.right))
                siteme = "right";
            builder.append(prefix + (isTail ? "└── " : "├── ") + "(" + siteme + ") " + node.item + "\n");
        } else {
            builder.append(prefix + (isTail ? "└── " : "├── ") + node.item + "\n");
        }
        List<Node<E>> children = null;
        if (node.left != null || node.right != null) {
            children = new ArrayList<Node<E>>(2);
            if (node.left != null)
                children.add(node.left);
            if (node.right != null)
                children.add(node.right);
        }
        if (children != null) {
            for (int i = 0; i < children.size() - 1; i++) {
                builder.append(getString(children.get(i), prefix + (isTail ? "    " : "│   "), false));
            }
            if (children.size() >= 1) {
                builder.append(getString(children.get(children.size() - 1), prefix + (isTail ? "    " : "│   "), true));
            }
        }

        return builder.toString();
    }
}
```

### 源码地址
代码地址：<br/>
https://github.com/mstao/data-structures/blob/master/Tree/src/pers/mingshan/tree/BinarySearchTree.java

测试代码地址如下：<br/>
https://github.com/mstao/data-structures/blob/master/Tree/src/pers/mingshan/tree/TreeTest.java