/* Copyright: Felix Pahl - github.com/joriki
 * Minor adjustments: Nick Treleaven */
import java.util.Random;

public class Question4622699 {
    final static int nrounds = 5;
    final static int ntables = 4;
    final static int nchairs = 4;
    final static int npeople = ntables * nchairs;

    final static Random random = new Random();

    static int [] [] counts = new int [npeople] [npeople];
    static int [] [] [] groups = new int [nrounds] [ntables] [nchairs];

    static int nrg;
    static int count;

    public static void main(String [] args) {
        for (int i = 0;i < nrounds;i++) {
            int [] left = new int [npeople];
            for (int j = 0;j < npeople;j++)
                left [j] = j;
            for (int j = 0,l = npeople;j < ntables;j++)
                for (int k = 0;k < nchairs;k++) {
                    int r = random.nextInt(l);
                    groups [i] [j] [k] = left [r];
                    left [r] = left [--l];
                }
        }

        computeEnergy ();

        int max = 0;
        int n = 0;

        for (double beta = 0;count < (npeople * (npeople - 1)) / 2;beta += 0.0000001) {
            int round = random.nextInt(nrounds);
            int [] [] g = groups [round];
            int t1 = random.nextInt(ntables);
            int t2 = random.nextInt(ntables - 1);
            int c1 = random.nextInt(nchairs);
            int c2 = random.nextInt(nchairs);

            if (t2 >= t1)
                t2++;

            int oldNRG = nrg;

            for (int i = 0;i < nchairs;i++) {
                if (i != c1) {
                    decrement (g [t1] [c1],g [t1] [i]);
                    increment (g [t2] [c2],g [t1] [i]);
                }
                if (i != c2) {
                    decrement (g [t2] [c2],g [t2] [i]);
                    increment (g [t1] [c1],g [t2] [i]);
                }
            }

            int t = g [t1] [c1];
            g [t1] [c1] = g [t2] [c2];
            g [t2] [c2] = t;

            if (nrg > oldNRG && random.nextDouble () > Math.exp (beta * (oldNRG - nrg))) {
                g [t2] [c2] = g [t1] [c1];
                g [t1] [c1] = t;

                for (int i = 0;i < nchairs;i++) {
                    if (i != c1) {
                        increment (g [t1] [c1],g [t1] [i]);
                        decrement (g [t2] [c2],g [t1] [i]);
                    }
                    if (i != c2) {
                        increment (g [t2] [c2],g [t2] [i]);
                        decrement (g [t1] [c1],g [t2] [i]);
                    }
                }
            }

            max = Math.max(max,count);

            if (++n % 0xfffff == 0)
                System.out.println(beta + " : " + nrg + " / " + count + " / " + max);
        }

        print();
    }

    static void computeEnergy() {
        for (int i = 0;i < nrounds;i++)
            for (int j = 0;j < ntables;j++)
                for (int k = 1;k < nchairs;k++)
                    for (int l = 0;l < k;l++)
                        if (l != k)
                            increment (groups [i] [j] [k],groups [i] [j] [l]);
    }

    static void increment (int i,int j) {
        if (i < j) {
            int t = i;
            i = j;
            j = t;
        }

        nrg += 2 * counts [i] [j] + 1;
        if (counts [i] [j]++ == 0)
            count++;
    }

    static void decrement (int i,int j) {
        if (i < j) {
            int t = i;
            i = j;
            j = t;
        }

        nrg -= 2 * counts [i] [j] - 1;
        if (--counts [i] [j] == 0)
            count--;
    }

    static void print () {
        // 1-based
        for (int i = 0;i < nrounds;i++) {
            for (int j = 0;j < ntables;j++) {
                for (int k = 0;k < nchairs;k++) {
                    System.out.format("%2d",groups [i] [j] [k] + 1);
                    System.out.print(" ");
                }
                System.out.print("   ");
            }
            System.out.println();
        }
        System.out.println();
        for (int p = 0;p < npeople;p++) {
            System.out.format("%2d: ", p + 1);
            for (int i = 0;i < nrounds;i++) {
                for (int j = 0;j < ntables;j++) {
                    for (int k = 0;k < nchairs;k++) {
                        if (groups [i] [j] [k] == p)
                        {
                            System.out.format("%2c", 'A' + (char) j);
                            System.out.print(" ");
                            break;
                        }
                    }
                }
            }
            System.out.println();
        }
    }
}
